import '../domain/entities/entities.dart';
import 'location_provider.dart';
import '../data/repositories/drift_repositories.dart';

/// Observes the existing 150m location stream and emits enter/exit for
/// user-confirmed geofenced places. Does not poll GPS on its own.
class GeofenceManager {
  final Map<String, bool> _inside = {};

  GeofenceEvent? observe({
    required GeoFix fix,
    required List<Place> places,
  }) {
    GeofenceEvent? event;
    for (final place in places.where((p) => p.geofenceEnabled && !p.forgotten)) {
      final d = haversineMeters(
        fix.latitude,
        fix.longitude,
        place.latitude,
        place.longitude,
      );
      final nowInside = d <= place.radius;
      final wasInside = _inside[place.id] ?? false;
      if (nowInside && !wasInside) {
        event = GeofenceEvent(place: place, entered: true, at: fix.timestamp);
      } else if (!nowInside && wasInside) {
        event = GeofenceEvent(place: place, entered: false, at: fix.timestamp);
      }
      _inside[place.id] = nowInside;
    }
    return event;
  }

  bool isInside(String placeId) => _inside[placeId] ?? false;
}
