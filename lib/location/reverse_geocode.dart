import 'package:geocoding/geocoding.dart';

import '../domain/enums/enums.dart';
import 'google_places.dart';
import 'place_classifier.dart';

class ReverseGeocode {
  ReverseGeocode({
    Geocoding? client,
    PlaceClassifier? classifier,
    GooglePlacesLookup? places,
  })  : _geo = client ?? Geocoding(),
        _classifier = classifier ?? PlaceClassifier(),
        _places = places ?? GooglePlacesLookup(classifier: classifier);

  final Geocoding _geo;
  final PlaceClassifier _classifier;
  final GooglePlacesLookup _places;

  Future<(String name, PlaceType type)> nameFor({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final google = await _places.nearby(latitude: latitude, longitude: longitude);
      if (google != null && google.name.isNotEmpty) {
        return (google.name, google.type);
      }
    } catch (_) {}
    try {
      final marks = await _geo.placemarkFromCoordinates(latitude, longitude);
      if (marks.isEmpty) return ('Nearby place', PlaceType.unknown);
      final p = marks.first;
      final parts = [
        p.name,
        p.street,
        p.subLocality,
        p.locality,
      ].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty);
      final name = parts.isEmpty ? 'Nearby place' : parts.first;
      final hay = '${p.name ?? ''} ${p.street ?? ''} ${p.subLocality ?? ''}';
      return (name, _classifier.classifyName(hay));
    } catch (_) {
      return ('Nearby place', PlaceType.unknown);
    }
  }
}
