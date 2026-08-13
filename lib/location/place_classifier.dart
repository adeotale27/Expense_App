import '../domain/entities/entities.dart';
import '../domain/enums/enums.dart';

class PlaceClassifier {
  PlaceType classifyName(String raw) {
    final n = raw.toLowerCase();
    if (n.contains('home') || n.contains('house')) return PlaceType.home;
    if (n.contains('office') || n.contains('work')) return PlaceType.work;
    if (n.contains('petrol') || n.contains('fuel') || n.contains('gas')) {
      return PlaceType.fuel;
    }
    if (n.contains('grocery') ||
        n.contains('supermarket') ||
        n.contains('mart') ||
        n.contains('milk')) {
      return PlaceType.grocery;
    }
    if (n.contains('restaurant') ||
        n.contains('cafe') ||
        n.contains('lunch') ||
        n.contains('food') ||
        n.contains('hotel')) {
      return PlaceType.food;
    }
    if (n.contains('mall') || n.contains('shop')) return PlaceType.shopping;
    if (n.contains('cinema') || n.contains('movie')) {
      return PlaceType.entertainment;
    }
    if (n.contains('pharmacy') || n.contains('hospital') || n.contains('clinic')) {
      return PlaceType.health;
    }
    if (n.contains('atm')) return PlaceType.atm;
    if (n.contains('bank')) return PlaceType.bank;
    if (n.contains('gym')) return PlaceType.gym;
    return PlaceType.unknown;
  }
}

class DemoCatalog {
  static Place of(String key, {required String userId, required String deviceId}) {
    final t = DateTime.utc(2020, 1, 1);
    final spec = switch (key) {
      'home' => (PlaceType.home, 'Home', 18.5204, 73.8567, 120.0),
      'office' => (PlaceType.work, 'Office', 18.5310, 73.8450, 100.0),
      'grocery' => (PlaceType.grocery, 'Grocery Store', 18.5240, 73.8500, 70.0),
      'restaurant' => (PlaceType.food, 'Restaurant', 18.5265, 73.8520, 70.0),
      'petrol' => (PlaceType.fuel, 'Petrol Pump', 18.5280, 73.8480, 70.0),
      'gym' => (PlaceType.gym, 'Gym', 18.5220, 73.8600, 70.0),
      'milk' => (PlaceType.grocery, 'Milk Store', 18.5212, 73.8550, 60.0),
      _ => (PlaceType.unknown, 'Unknown place', 18.5100, 73.8700, 70.0),
    };
    return Place(
      id: 'demo-$key',
      userId: userId,
      name: spec.$2,
      type: spec.$1,
      latitude: spec.$3,
      longitude: spec.$4,
      radius: spec.$5,
      createdAt: t,
      updatedAt: t,
      deviceId: deviceId,
    );
  }

  static List<Place> all({required String userId, required String deviceId}) => [
        for (final k in [
          'home',
          'office',
          'grocery',
          'restaurant',
          'petrol',
          'gym',
          'milk'
        ])
          of(k, userId: userId, deviceId: deviceId),
      ];
}
