import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/google_oauth.dart';
import '../domain/enums/enums.dart';
import 'place_classifier.dart';

class PlaceHint {
  const PlaceHint({
    required this.name,
    required this.type,
    this.types = const [],
    this.distanceMeters,
  });

  final String name;
  final PlaceType type;
  final List<String> types;
  final double? distanceMeters;
}

/// Nearby Search against Google Places. Key is optional — we fall back to OS geocoding.
class GooglePlacesLookup {
  GooglePlacesLookup({http.Client? client, String? apiKey, PlaceClassifier? classifier})
      : _client = client ?? http.Client(),
        _apiKey = apiKey,
        _classifier = classifier ?? PlaceClassifier();

  final http.Client _client;
  final String? _apiKey;
  final PlaceClassifier _classifier;

  Future<PlaceHint?> nearby({
    required double latitude,
    required double longitude,
    int radiusMeters = 80,
  }) async {
    final key = (_apiKey ?? await GoogleOAuth.resolveMapsKey()).trim();
    if (key.isEmpty) return null;
    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/nearbysearch/json', {
      'location': '$latitude,$longitude',
      'radius': '$radiusMeters',
      'key': key,
    });
    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      return pickBest(jsonDecode(res.body) as Map<String, dynamic>, _classifier);
    } catch (_) {
      return null;
    }
  }

  static PlaceHint? pickBest(Map<String, dynamic> body, PlaceClassifier classifier) {
    final results = body['results'];
    if (results is! List || results.isEmpty) return null;
    PlaceHint? best;
    var bestScore = -1;
    for (final raw in results) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final name = (map['name'] as String?)?.trim();
      if (name == null || name.isEmpty) continue;
      final types = (map['types'] as List?)?.whereType<String>().toList() ?? const [];
      final type = classifier.classifyGoogleTypes(types) ?? classifier.classifyName(name);
      final score = _score(types, type);
      if (score > bestScore) {
        bestScore = score;
        best = PlaceHint(name: name, type: type, types: types);
      }
    }
    return best;
  }

  static int _score(List<String> types, PlaceType type) {
    var score = 0;
    if (types.contains('restaurant') || types.contains('meal_takeaway') || types.contains('meal_delivery')) {
      score += 50;
    }
    if (types.contains('cafe') || types.contains('bakery')) score += 40;
    if (types.contains('gas_station')) score += 45;
    if (types.contains('grocery_or_supermarket') || types.contains('supermarket')) score += 40;
    if (type == PlaceType.food || type == PlaceType.cafe || type == PlaceType.fuel) score += 10;
    if (types.contains('point_of_interest')) score += 1;
    if (types.contains('political') || types.contains('route') || types.contains('locality')) score -= 20;
    return score;
  }
}
