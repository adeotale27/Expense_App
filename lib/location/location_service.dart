import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/logging/app_log.dart';
import '../core/utils/dates.dart';
import '../core/utils/ids.dart';
import '../domain/entities/entities.dart';
import '../domain/enums/enums.dart';
import '../domain/repositories/repositories.dart';
import '../notifications/notification_service.dart';
import 'behavior_confidence.dart';
import 'geofence_manager.dart';
import 'movement_engine.dart';
import 'opportunity_engine.dart';
import 'place_classifier.dart';
import 'place_memory.dart';
import 'smart_prompt_manager.dart';
import 'location_provider.dart';

class LocationRuntime {
  LocationRuntime({
    required this.userId,
    required this.deviceId,
    required this.places,
    required this.opportunities,
    required this.categories,
    required this.settingsRepo,
    required this.notifications,
    required this.provider,
    required this.simulator,
    required this.intel,
  });

  final String userId;
  final String deviceId;
  final PlaceRepository places;
  final OpportunityRepository opportunities;
  final CategoryRepository categories;
  final SettingsRepository settingsRepo;
  final NotificationService notifications;
  final LocationProvider provider;
  final SimulatedLocationProvider simulator;
  final IntelRepository intel;

  final movement = MovementEngine();
  final engine = OpportunityEngine();
  final classifier = PlaceClassifier();
  final geofences = GeofenceManager();
  final confidence = BehaviorConfidence();
  late final memory = PlaceMemory(
    places: places,
    classifier: classifier,
    precise: provider.getPreciseLocation,
  );
  late final prompts = SmartPromptManager(intel);

  LocationState state = LocationState.unknown;
  Place? currentPlace;
  int lastScore = 0;
  String lastEvent = 'idle';
  PlaceSuggestion? pendingSuggestion;
  GeofenceEvent? lastGeofence;
  GeoFix? lastFix;
  bool permissionGranted = false;
  bool monitoring = false;
  StreamSubscription<GeoFix>? _sub;
  final _pulses = StreamController<int>.broadcast();
  int _pulse = 0;

  Stream<int> get pulses => _pulses.stream;

  void _pulseUi() {
    _pulse += 1;
    if (!_pulses.isClosed) _pulses.add(_pulse);
  }

  Future<void> start({bool force = false}) async {
    if (force) {
      await _sub?.cancel();
      _sub = null;
      monitoring = false;
      await provider.stopMonitoring();
    }
    if (_sub != null) return;
    permissionGranted = await provider.hasPermission();
    if (!permissionGranted) {
      lastEvent = 'needs-permission';
      _pulseUi();
      return;
    }
    final settings = await settingsRepo.get(userId);
    final known = await places.all();
    if (settings.homePlaceId != null) {
      movement.homePlace = await places.getById(settings.homePlaceId!);
    }
    movement.homePlace ??=
        known.where((p) => p.type == PlaceType.home).firstOrNull;
    _sub = provider.fixes.listen(_onFix);
    await provider.startMonitoring();
    monitoring = true;
    lastEvent = 'listening';
    _pulseUi();
    try {
      final here = await provider.getCurrentLocation();
      if (here != null) await _onFix(here);
    } catch (_) {}
  }

  Future<void> restart() => start(force: true);

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    monitoring = false;
    await provider.stopMonitoring();
  }

  Future<void> _onFix(GeoFix fix) async {
    lastFix = fix;
    lastEvent = 'fix';
    _pulseUi();
    final settings = await settingsRepo.get(userId);
    var known = await places.all();
    movement.homePlace ??=
        known.where((p) => p.type == PlaceType.home).firstOrNull;
    final fence = geofences.observe(fix: fix, places: known);
    if (fence != null) {
      lastGeofence = fence;
      lastEvent = fence.entered ? 'geofence-enter' : 'geofence-exit';
      AppLog.location(
        '${fence.entered ? 'Entered' : 'Left'} ${fence.place.name}',
      );
    }
    await memory.observeUnknown(
      fix: fix,
      known: known,
      userId: userId,
      deviceId: deviceId,
      minStopMinutes: settings.minStopMinutes,
      enabled: settings.smartPlaceDetection,
    );
    known = await places.all();
    final tick = movement.tick(
      fix: fix,
      knownPlaces: known,
      minStopMinutes: settings.minStopMinutes,
    );
    state = tick.state;
    currentPlace = tick.currentPlace;
    AppLog.movement(state.name);
    final visit = tick.completedVisit;
    if (visit != null) {
      AppLog.location('Visit ended ${visit.place.name} ${visit.duration}');
      await _handleVisit(visit, settings);
    }
    _pulseUi();
  }

  Future<void> _handleVisit(VisitEvent visit, AppSettings settings) async {
    final local = visit.startedAt.toLocal();
    await intel.recordVisit(
      VisitLog(
        id: newId(),
        userId: userId,
        placeId: visit.place.id,
        startedAt: visit.startedAt.toUtc(),
        endedAt: visit.endedAt.toUtc(),
        durationSeconds: visit.duration.inSeconds,
        hourOfDay: local.hour,
        weekday: local.weekday,
        passThrough: visit.passThrough,
      ),
    );
    final updated = visit.place.copyWith(
      visitCount: visit.place.visitCount + (visit.passThrough ? 0 : 1),
      lastVisitedAt: visit.endedAt.toUtc(),
      firstVisitedAt: visit.place.firstVisitedAt ?? visit.startedAt.toUtc(),
      updatedAt: utcNow(),
    );
    await places.upsert(updated);

    await _maybePlaceSuggestion(updated, settings);

    if (!settings.expensePrompts) return;
    final pending = await opportunities.pending();
    final recent = pending.any((o) => o.placeId == visit.place.id);
    final cat = await categories.byName(suggestedCategoryName(visit.place.type));
    final throttle = await prompts.allow(
      settings: settings,
      kind: PromptKind.expenseOpportunity,
      placeId: visit.place.id,
      dismissedRecently: recent,
    );
    final decision = engine.evaluate(
      visit,
      PromptContext(
        settings: settings,
        weights: ScoringWeights.fromMap(
          settings.scoring.weights.isEmpty ? null : settings.scoring.weights,
        ),
        thresholds: ConfidenceThresholds(
          ignoreBelow: settings.scoring.ignoreBelow,
          lowBelow: settings.scoring.lowBelow,
          possibleBelow: settings.scoring.possibleBelow,
        ),
        promptsToday: pending.length,
        recentPromptAtPlace: recent,
        previouslySpent: visit.place.totalSpendMinor > 0,
        dismissedRecently: !throttle.allow,
      ),
    );
    lastScore = decision.score;
    AppLog.opportunity('Confidence = ${decision.score} ${decision.reason}');
    if (!decision.create || !throttle.allow) return;

    final opp = engine.toOpportunity(
      visit: visit,
      userId: userId,
      deviceId: deviceId,
      score: decision.score,
      categoryId: cat?.id,
    );
    await opportunities.upsert(opp);
    final nid = 'opp-${opp.id}';
    await opportunities.upsert(opp.copyWith(notificationId: nid, updatedAt: utcNow()));
    await intel.recordPrompt(
      PromptEvent(
        id: newId(),
        userId: userId,
        kind: PromptKind.expenseOpportunity,
        placeId: visit.place.id,
        createdAt: utcNow(),
      ),
    );
    await notifications.showOpportunity(opp, visit.place);
  }

  Future<void> _maybePlaceSuggestion(Place place, AppSettings settings) async {
    final visits = await intel.visitsFor(place.id);
    final promptsLog = await intel.recentPrompts();
    final declinedHome = {
      for (final p in promptsLog.where((e) =>
          e.kind == PromptKind.homeSuggestion && e.response == 'no'))
        if (p.placeId != null) p.placeId!,
    };
    final declinedWork = {
      for (final p in promptsLog.where((e) =>
          e.kind == PromptKind.workSuggestion && e.response == 'no'))
        if (p.placeId != null) p.placeId!,
    };
    final declinedType = {
      for (final p in promptsLog.where((e) =>
          e.kind == PromptKind.placeTypeSuggestion && e.response == 'no'))
        if (p.placeId != null) p.placeId!,
    };
    final suggestion = confidence.maybeSuggest(
      place: place,
      visits: visits,
      settings: settings,
      declinedHome: declinedHome,
      declinedWork: declinedWork,
      declinedType: declinedType,
    );
    if (suggestion == null) return;
    final gate = await prompts.allow(
      settings: settings,
      kind: suggestion.kind,
      placeId: place.id,
    );
    if (!gate.allow) return;
    pendingSuggestion = suggestion;
    await intel.recordPrompt(
      PromptEvent(
        id: newId(),
        userId: userId,
        kind: suggestion.kind,
        placeId: place.id,
        createdAt: utcNow(),
      ),
    );
    await notifications.showPlaceSuggestion(suggestion);
  }

  Future<void> answerSuggestion(PlaceSuggestion suggestion, bool yes) async {
    pendingSuggestion = null;
    await intel.recordPrompt(
      PromptEvent(
        id: newId(),
        userId: userId,
        kind: suggestion.kind,
        placeId: suggestion.place.id,
        createdAt: utcNow(),
        response: yes ? 'yes' : 'no',
      ),
    );
    if (!yes) return;
    var place = suggestion.place;
    var settings = await settingsRepo.get(userId);
    if (suggestion.kind == PromptKind.homeSuggestion) {
      place = place.copyWith(
        type: PlaceType.home,
        name: place.userConfirmedName ? place.name : 'Home',
        geofenceEnabled: true,
        userConfirmedName: true,
        updatedAt: utcNow(),
      );
      await settingsRepo.save(settings.copyWith(homePlaceId: place.id));
      movement.homePlace = place;
    } else if (suggestion.kind == PromptKind.workSuggestion) {
      place = place.copyWith(
        type: PlaceType.work,
        name: place.userConfirmedName ? place.name : 'Work',
        geofenceEnabled: true,
        userConfirmedName: true,
        updatedAt: utcNow(),
      );
      await settingsRepo.save(settings.copyWith(workPlaceId: place.id));
    } else {
      final guessed = classifier.suggestFromPattern(
        nightVisits: 0,
        weekdayDaytimeVisits: 0,
        eveningVisits: 1,
        totalVisits: place.visitCount,
        current: PlaceType.hangout,
      );
      place = place.copyWith(
        type: guessed,
        userConfirmedName: true,
        updatedAt: utcNow(),
      );
    }
    await places.upsert(place);
  }

  Future<void> simulate({
    required String startKey,
    required String stayKey,
    required Duration stay,
    bool returnHome = true,
  }) async {
    final catalog = DemoCatalog.all(userId: userId, deviceId: deviceId);
    for (final p in catalog) {
      final existing = await places.getById(p.id);
      if (existing == null) await places.upsert(p);
    }
    final start = DemoCatalog.of(startKey, userId: userId, deviceId: deviceId);
    final stayP = DemoCatalog.of(stayKey, userId: userId, deviceId: deviceId);
    final home = DemoCatalog.of('home', userId: userId, deviceId: deviceId);
    final now = DateTime.now();
    simulator.emit(GeoFix(
      latitude: start.latitude,
      longitude: start.longitude,
      timestamp: now,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 40));
    simulator.emit(GeoFix(
      latitude: stayP.latitude,
      longitude: stayP.longitude,
      timestamp: now.add(const Duration(seconds: 20)),
    ));
    await Future<void>.delayed(const Duration(milliseconds: 40));
    simulator.emit(GeoFix(
      latitude: stayP.latitude,
      longitude: stayP.longitude,
      timestamp: now.add(const Duration(seconds: 20) + stay),
    ));
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (returnHome) {
      simulator.emit(GeoFix(
        latitude: home.latitude,
        longitude: home.longitude,
        timestamp: now.add(const Duration(seconds: 20) + stay + const Duration(minutes: 2)),
      ));
    } else {
      simulator.emit(GeoFix(
        latitude: stayP.latitude + 0.01,
        longitude: stayP.longitude + 0.01,
        timestamp: now.add(const Duration(seconds: 20) + stay + const Duration(minutes: 1)),
      ));
    }
  }

  Future<Place> rememberUnknown(GeoFix fix, String name) async {
    final place = Place(
      id: newId(),
      userId: userId,
      name: name,
      type: classifier.classifyName(name),
      latitude: fix.latitude,
      longitude: fix.longitude,
      radius: 150,
      geofenceEnabled: true,
      userConfirmedName: true,
      firstVisitedAt: utcNow(),
      lastVisitedAt: utcNow(),
      createdAt: utcNow(),
      updatedAt: utcNow(),
      deviceId: deviceId,
    );
    await places.upsert(place);
    return place;
  }
}

final locationRuntimeProvider = Provider<LocationRuntime>((ref) {
  throw UnimplementedError('locationRuntimeProvider override required');
});
