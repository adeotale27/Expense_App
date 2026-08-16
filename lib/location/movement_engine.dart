import '../data/repositories/drift_repositories.dart';
import '../domain/entities/entities.dart';
import '../domain/enums/enums.dart';
import 'location_provider.dart';

class MovementTick {
  const MovementTick({
    required this.state,
    this.completedVisit,
    this.currentPlace,
  });

  final LocationState state;
  final VisitEvent? completedVisit;
  final Place? currentPlace;
}

class MovementEngine {
  MovementEngine({this.homePlace});

  Place? homePlace;
  LocationState state = LocationState.unknown;
  Place? currentPlace;
  DateTime? visitStartedAt;
  GeoFix? lastFix;
  bool _wasHome = false;

  MovementTick tick({
    required GeoFix fix,
    required List<Place> knownPlaces,
    required int minStopMinutes,
  }) {
    lastFix = fix;
    final nearby = _resolve(fix, knownPlaces);
    final atHome = homePlace != null &&
        haversineMeters(
              fix.latitude,
              fix.longitude,
              homePlace!.latitude,
              homePlace!.longitude,
            ) <=
            homePlace!.radius;

    VisitEvent? completed;

    if (atHome) {
      if (currentPlace != null && currentPlace!.type != PlaceType.home) {
        completed = _finishVisit(
          endedAt: fix.timestamp,
          minStopMinutes: minStopMinutes,
          returnedHome: true,
          cameFromHome: _wasHome,
        );
      }
      currentPlace = homePlace;
      visitStartedAt = visitStartedAt ?? fix.timestamp;
      state = LocationState.home;
      _wasHome = true;
      return MovementTick(state: state, completedVisit: completed, currentPlace: currentPlace);
    }

    if (nearby != null) {
      if (currentPlace != null && currentPlace!.id != nearby.id) {
        completed = _finishVisit(
          endedAt: fix.timestamp,
          minStopMinutes: minStopMinutes,
          returnedHome: false,
          cameFromHome: _wasHome,
        );
        visitStartedAt = fix.timestamp;
      } else {
        visitStartedAt ??= fix.timestamp;
      }
      currentPlace = nearby;
      final dwell = fix.timestamp.difference(visitStartedAt!);
      if (dwell.inMinutes >= minStopMinutes) {
        state = LocationState.staying;
      } else {
        state = LocationState.arriving;
      }
      _wasHome = false;
      return MovementTick(state: state, completedVisit: completed, currentPlace: currentPlace);
    }

    if (currentPlace != null && currentPlace!.type != PlaceType.home) {
      completed = _finishVisit(
        endedAt: fix.timestamp,
        minStopMinutes: minStopMinutes,
        returnedHome: false,
        cameFromHome: _wasHome,
      );
    }
    currentPlace = null;
    visitStartedAt = null;
    state = _wasHome ? LocationState.moving : LocationState.travelingHome;
    if (!atHome) _wasHome = false;
    return MovementTick(state: state, completedVisit: completed);
  }

  VisitEvent? _finishVisit({
    required DateTime endedAt,
    required int minStopMinutes,
    required bool returnedHome,
    required bool cameFromHome,
  }) {
    final place = currentPlace;
    final start = visitStartedAt;
    if (place == null || start == null) return null;
    final duration = endedAt.difference(start);
    final passThrough = duration.inMinutes < minStopMinutes && duration.inSeconds < 90;
    return VisitEvent(
      place: place,
      startedAt: start,
      endedAt: endedAt,
      duration: duration,
      passThrough: passThrough,
      returnedHome: returnedHome,
      cameFromHome: cameFromHome,
      locationConfidence: 0.85,
    );
  }

  Place? _resolve(GeoFix fix, List<Place> known) {
    Place? best;
    var bestD = double.infinity;
    for (final p in known) {
      final d = haversineMeters(fix.latitude, fix.longitude, p.latitude, p.longitude);
      if (d <= p.radius && d < bestD) {
        best = p;
        bestD = d;
      }
    }
    return best;
  }
}
