import '../core/utils/ids.dart';
import '../data/repositories/drift_repositories.dart';
import '../domain/entities/entities.dart';
import '../domain/enums/enums.dart';
import '../domain/repositories/repositories.dart';
import 'location_provider.dart';
import 'place_classifier.dart';

/// Remembers meaningful stops as local places without reverse-geocoding.
class PlaceMemory {
  PlaceMemory({
    required this.places,
    required this.classifier,
  });

  final PlaceRepository places;
  final PlaceClassifier classifier;

  GeoFix? _unknownStart;

  Future<Place?> observeUnknown({
    required GeoFix fix,
    required List<Place> known,
    required String userId,
    required String deviceId,
    required int minStopMinutes,
    required bool enabled,
  }) async {
    if (!enabled) {
      _unknownStart = null;
      return null;
    }
    final nearby = known.where((p) {
      return haversineMeters(fix.latitude, fix.longitude, p.latitude, p.longitude) <=
          p.radius;
    }).toList();
    if (nearby.isNotEmpty) {
      _unknownStart = null;
      return nearby.first;
    }

    if (_unknownStart == null) {
      _unknownStart = fix;
      return null;
    }
    final drift = haversineMeters(
      _unknownStart!.latitude,
      _unknownStart!.longitude,
      fix.latitude,
      fix.longitude,
    );
    if (drift > 80) {
      _unknownStart = fix;
      return null;
    }
    final dwell = fix.timestamp.difference(_unknownStart!.timestamp);
    if (dwell.inMinutes < minStopMinutes) return null;

    final place = Place(
      id: newId(),
      userId: userId,
      name: _untitledName(fix),
      type: PlaceType.unknown,
      latitude: _unknownStart!.latitude,
      longitude: _unknownStart!.longitude,
      radius: 150,
      visitCount: 1,
      firstVisitedAt: _unknownStart!.timestamp.toUtc(),
      lastVisitedAt: fix.timestamp.toUtc(),
      confidence: 20,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      deviceId: deviceId,
    );
    await places.upsert(place);
    _unknownStart = null;
    return place;
  }

  Future<Place> confirmName(Place place, String name) {
    final typed = classifier.classifyName(name);
    return places
        .upsert(
          place.copyWith(
            name: name.trim(),
            type: typed == PlaceType.unknown ? place.type : typed,
            userConfirmedName: true,
            geofenceEnabled: true,
            updatedAt: DateTime.now().toUtc(),
          ),
        )
        .then((_) async => (await places.getById(place.id)) ?? place);
  }

  String _untitledName(GeoFix fix) {
    final lat = fix.latitude.toStringAsFixed(3);
    final lng = fix.longitude.toStringAsFixed(3);
    return 'Place near $lat, $lng';
  }
}
