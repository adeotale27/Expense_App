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
import 'movement_engine.dart';
import 'opportunity_engine.dart';
import 'place_classifier.dart';
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

  final movement = MovementEngine();
  final engine = OpportunityEngine();
  final classifier = PlaceClassifier();

  LocationState state = LocationState.unknown;
  Place? currentPlace;
  int lastScore = 0;
  String lastEvent = 'idle';
  StreamSubscription<GeoFix>? _sub;

  Future<void> start() async {
    final settings = await settingsRepo.get(userId);
    final known = await places.all();
    if (settings.homePlaceId != null) {
      movement.homePlace = await places.getById(settings.homePlaceId!);
    }
    movement.homePlace ??=
        known.where((p) => p.type == PlaceType.home).firstOrNull;
    _sub = provider.fixes.listen(_onFix);
    await provider.startMonitoring();
  }

  Future<void> stop() async {
    await _sub?.cancel();
    await provider.stopMonitoring();
  }

  Future<void> _onFix(GeoFix fix) async {
    lastEvent = 'fix';
    final settings = await settingsRepo.get(userId);
    var known = await places.all();
    if (known.isEmpty) {
      known = DemoCatalog.all(userId: userId, deviceId: deviceId);
      for (final p in known) {
        await places.upsert(p);
      }
    }
    movement.homePlace ??=
        known.where((p) => p.type == PlaceType.home).firstOrNull;
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
  }

  Future<void> _handleVisit(VisitEvent visit, AppSettings settings) async {
    final pending = await opportunities.pending();
    final recent = pending.any((o) => o.placeId == visit.place.id);
    final cat = await categories.byName(suggestedCategoryName(visit.place.type));
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
      ),
    );
    lastScore = decision.score;
    AppLog.opportunity('Confidence = ${decision.score} ${decision.reason}');
    if (!decision.create) return;

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
    await notifications.showOpportunity(opp, visit.place);
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

  Future<void> maybeLearnPlace(Place place) async {
    if (place.visitCount == 10 && place.name.startsWith('Near ')) {
      AppLog.place('You visit this place often.');
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
