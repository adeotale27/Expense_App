import '../../domain/entities/entities.dart';
import '../../domain/enums/enums.dart';

class HabitEngine {
  SpendingHabits learn({
    required List<Expense> expenses,
    required List<Place> places,
    required List<VisitLog> visits,
    AppSettings? settings,
  }) {
    if (expenses.isEmpty) {
      return SpendingHabits(
        recentPayment: settings?.lastPaymentMethod ?? PaymentMethod.upi,
        frequentPayment: settings?.lastPaymentMethod ?? PaymentMethod.upi,
        recentCategoryId: settings?.lastCategoryId,
      );
    }
    final cats = <String, int>{};
    final methods = <PaymentMethod, int>{};
    final placeSpend = <String, int>{};
    for (final e in expenses) {
      cats[e.categoryId] = (cats[e.categoryId] ?? 0) + 1;
      methods[e.paymentMethod] = (methods[e.paymentMethod] ?? 0) + 1;
      if (e.placeId != null) {
        placeSpend[e.placeId!] = (placeSpend[e.placeId!] ?? 0) + 1;
      }
    }
    String? top(Map<String, int> map) {
      if (map.isEmpty) return null;
      final ranked = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return ranked.first.key;
    }

    PaymentMethod topMethod() {
      if (methods.isEmpty) return settings?.lastPaymentMethod ?? PaymentMethod.upi;
      final ranked = methods.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final best = ranked.first.key;
      if (best == PaymentMethod.notSpecified && ranked.length > 1) {
        return ranked[1].key;
      }
      return best == PaymentMethod.notSpecified
          ? PaymentMethod.upi
          : best;
    }

    final recent = [...expenses]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final recentCat = recent.first.categoryId;
    final recentPay = recent.first.paymentMethod == PaymentMethod.notSpecified
        ? topMethod()
        : recent.first.paymentMethod;

    final groceryPlaces = places
        .where((p) => p.type == PlaceType.grocery && p.visitCount >= 3)
        .map((p) => p.id)
        .toList();
    final hangouts = places.where((p) {
      if (p.type == PlaceType.hangout ||
          p.type == PlaceType.cafe ||
          p.type == PlaceType.gaming ||
          p.type == PlaceType.entertainment) {
        return p.visitCount >= 3;
      }
      final pv = visits.where((v) => v.placeId == p.id).toList();
      if (pv.length < 3) return false;
      final evenings =
          pv.where((v) => v.hourOfDay >= 17 && v.hourOfDay <= 23).length;
      return evenings / pv.length >= 0.45;
    }).map((p) => p.id).toList();

    final amounts = expenses.map((e) => e.amount.minorUnits).toList()..sort();
    final quick = <int>{10000, 20000, 50000};
    if (amounts.isNotEmpty) {
      quick.add(_roundNice(amounts[amounts.length ~/ 2]));
    }

    return SpendingHabits(
      frequentCategoryId: top(cats),
      recentCategoryId: settings?.lastCategoryId ?? recentCat,
      frequentPayment: topMethod(),
      recentPayment: settings?.lastPaymentMethod ?? recentPay,
      frequentPlaceIds: (placeSpend.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .take(5)
          .map((e) => e.key)
          .toList(),
      groceryLike: groceryPlaces.isNotEmpty,
      hangoutPlaceIds: hangouts,
      typicalQuickAmounts: (quick.toList()..sort()).take(4).toList(),
    );
  }

  int _roundNice(int minor) {
    final rupees = (minor / 100).round();
    if (rupees <= 100) return 10000;
    if (rupees <= 250) return 20000;
    if (rupees <= 600) return 50000;
    return 100000;
  }

  List<Category> orderCategories(List<Category> active, SpendingHabits habits) {
    final recent = <Category>[];
    final frequent = <Category>[];
    final rest = <Category>[];
    for (final c in active) {
      if (c.id == habits.recentCategoryId) {
        recent.add(c);
      } else if (c.id == habits.frequentCategoryId) {
        frequent.add(c);
      } else {
        rest.add(c);
      }
    }
    return [...recent, ...frequent, ...rest];
  }
}
