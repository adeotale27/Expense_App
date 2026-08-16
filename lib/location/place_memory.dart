import '../core/utils/ids.dart';
import '../data/repositories/drift_repositories.dart';
import '../domain/entities/entities.dart';
import '../domain/enums/enums.dart';
import '../domain/repositories/repositories.dart';
import 'location_provider.dart';
import 'place_classifier.dart';
import 'reverse_geocode.dart';

/// Remembers meaningful stops as local places.
/// Reverse-geocoding is a name hint only — never an automatic expense.
class PlaceMemory {
  PlaceMemory({
    required this.places,
    required this.classifier,
    ReverseGeocode? geocode,
    this.precise,
  }) : geocode = geocode ?? ReverseGeocode(classifier: classifier);

  final PlaceRepository places;
  final PlaceClassifier classifier;
  final ReverseGeocode geocode;
  final Future<GeoFix?> Function()? precise;

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

    var lat = _unknownStart!.latitude;
    var lng = _unknownStart!.longitude;
    try {
      final refined = await precise?.call();
      if (refined != null) {
        final jump = haversineMeters(lat, lng, refined.latitude, refined.longitude);
        if (jump < 120) {
          lat = refined.latitude;
          lng = refined.longitude;
        }
      }
    } catch (_) {}

    final hint = await geocode.nameFor(latitude: lat, longitude: lng);
    final commercial = hint.$2 == PlaceType.food ||
        hint.$2 == PlaceType.cafe ||
        hint.$2 == PlaceType.fuel ||
        hint.$2 == PlaceType.grocery;
    final place = Place(
      id: newId(),
      userId: userId,
      name: hint.$1,
      type: hint.$2,
      latitude: lat,
      longitude: lng,
      radius: commercial ? 70 : 120,
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
}
