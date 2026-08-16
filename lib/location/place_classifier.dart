import '../domain/entities/entities.dart';
import '../domain/enums/enums.dart';

class PlaceClassifier {
  PlaceType classifyName(String raw) {
    final n = raw.toLowerCase();
    if (n.contains('home') || n.contains('house') || n.contains('apartment')) {
      return PlaceType.home;
    }
    if (n.contains('office') ||
        n.contains('work') ||
        n.contains('it park') ||
        n.contains('campus') ||
        n.contains('cowork')) {
      return PlaceType.work;
    }
    if (n.contains('petrol') || n.contains('fuel') || n.contains('gas')) {
      return PlaceType.fuel;
    }
    if (n.contains('grocery') ||
        n.contains('supermarket') ||
        n.contains('mart') ||
        n.contains('milk') ||
        n.contains('kirana')) {
      return PlaceType.grocery;
    }
    if (n.contains('cafe') || n.contains('coffee') || n.contains('starbucks')) {
      return PlaceType.cafe;
    }
    if (n.contains('restaurant') ||
        n.contains('lunch') ||
        n.contains('food') ||
        n.contains('hotel') ||
        n.contains('dine') ||
        n.contains('mcdonald') ||
        n.contains('kfc') ||
        n.contains('domino') ||
        n.contains('pizza') ||
        n.contains('biryani') ||
        n.contains('dhaba') ||
        n.contains('kitchen') ||
        n.contains('eatery') ||
        n.contains('bistro')) {
      return PlaceType.food;
    }
    if (n.contains('cinema') || n.contains('movie') || n.contains('pvr') || n.contains('inox')) {
      return PlaceType.cinema;
    }
    if (n.contains('game') || n.contains('arena') || n.contains('esports') || n.contains('playstation')) {
      return PlaceType.gaming;
    }
    if (n.contains('mall') || n.contains('shop')) return PlaceType.shopping;
    if (n.contains('college') || n.contains('school') || n.contains('academy') || n.contains('university')) {
      return PlaceType.school;
    }
    if (n.contains('hospital') || n.contains('clinic')) return PlaceType.hospital;
    if (n.contains('pharmacy') || n.contains('chemist')) return PlaceType.health;
    if (n.contains('atm')) return PlaceType.atm;
    if (n.contains('bank')) return PlaceType.bank;
    if (n.contains('gym') || n.contains('fitness')) return PlaceType.gym;
    if (n.contains('hangout') || n.contains('friends')) return PlaceType.hangout;
    return PlaceType.unknown;
  }

  PlaceType? classifyGoogleTypes(List<String> types) {
    final t = types.map((e) => e.toLowerCase()).toSet();
    if (t.contains('restaurant') ||
        t.contains('meal_takeaway') ||
        t.contains('meal_delivery')) {
      return PlaceType.food;
    }
    if (t.contains('cafe') || t.contains('bakery') || t.contains('bar')) {
      return PlaceType.cafe;
    }
    if (t.contains('gas_station')) return PlaceType.fuel;
    if (t.contains('grocery_or_supermarket') ||
        t.contains('supermarket') ||
        t.contains('convenience_store')) {
      return PlaceType.grocery;
    }
    if (t.contains('movie_theater')) return PlaceType.cinema;
    if (t.contains('gym')) return PlaceType.gym;
    if (t.contains('hospital') || t.contains('doctor')) return PlaceType.hospital;
    if (t.contains('pharmacy')) return PlaceType.health;
    if (t.contains('shopping_mall') || t.contains('clothing_store') || t.contains('store')) {
      return PlaceType.shopping;
    }
    if (t.contains('school') || t.contains('university')) return PlaceType.school;
    if (t.contains('bank')) return PlaceType.bank;
    if (t.contains('atm')) return PlaceType.atm;
    return null;
  }

  PlaceType suggestFromPattern({
    required int nightVisits,
    required int weekdayDaytimeVisits,
    required int eveningVisits,
    required int totalVisits,
    PlaceType current = PlaceType.unknown,
  }) {
    if (current == PlaceType.home || current == PlaceType.work) return current;
    if (totalVisits >= 4 && nightVisits / totalVisits >= 0.5) return PlaceType.home;
    if (totalVisits >= 4 && weekdayDaytimeVisits / totalVisits >= 0.55) {
      return PlaceType.work;
    }
    if (totalVisits >= 3 && eveningVisits / totalVisits >= 0.5) {
      return PlaceType.hangout;
    }
    return current;
  }
}

class DemoCatalog {
  static Place of(String key, {required String userId, required String deviceId}) {
    final t = DateTime.utc(2020, 1, 1);
    final spec = switch (key) {
      'home' => (PlaceType.home, 'Home', 18.5204, 73.8567, 150.0),
      'office' => (PlaceType.work, 'Office', 18.5310, 73.8450, 150.0),
      'grocery' => (PlaceType.grocery, 'Grocery Store', 18.5240, 73.8500, 150.0),
      'restaurant' => (PlaceType.food, 'Restaurant', 18.5265, 73.8520, 150.0),
      'petrol' => (PlaceType.fuel, 'Petrol Pump', 18.5280, 73.8480, 150.0),
      'gym' => (PlaceType.gym, 'Gym', 18.5220, 73.8600, 150.0),
      'milk' => (PlaceType.grocery, 'Milk Store', 18.5212, 73.8550, 150.0),
      'mall' => (PlaceType.shopping, 'Phoenix Mall', 18.5190, 73.8620, 150.0),
      'cafe' => (PlaceType.cafe, 'Cafe', 18.5235, 73.8510, 150.0),
      'gaming' => (PlaceType.gaming, 'Gaming Arena', 18.5255, 73.8580, 150.0),
      'cinema' => (PlaceType.cinema, 'Cinema', 18.5275, 73.8540, 150.0),
      _ => (PlaceType.unknown, 'Unknown place', 18.5100, 73.8700, 150.0),
    };
    return Place(
      id: 'demo-$key',
      userId: userId,
      name: spec.$2,
      type: spec.$1,
      latitude: spec.$3,
      longitude: spec.$4,
      radius: spec.$5,
      geofenceEnabled: spec.$1 == PlaceType.home || spec.$1 == PlaceType.work,
      userConfirmedName: true,
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
          'milk',
          'mall',
          'cafe',
          'gaming',
          'cinema',
        ])
          of(k, userId: userId, deviceId: deviceId),
      ];
}
