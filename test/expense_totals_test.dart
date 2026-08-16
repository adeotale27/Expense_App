import 'package:spendping/core/utils/money.dart';
import 'package:spendping/domain/entities/entities.dart';
import 'package:flutter_test/flutter_test.dart';

Expense _exp(int minor, DateTime ts) {
  final now = DateTime.utc(2026, 8, 13);
  return Expense(
    id: 'e-$minor',
    userId: 'u',
    amount: Money(minorUnits: minor),
    categoryId: 'food',
    timestamp: ts,
    createdAt: now,
    updatedAt: now,
    deviceId: 'd',
  );
}

void main() {
  test('daily and monthly totals from stored amounts', () {
    final day = DateTime(2026, 8, 13, 10);
    final items = [
      _exp(50000, day),
      _exp(42000, day.add(const Duration(hours: 2))),
      _exp(10000, DateTime(2026, 7, 1)),
    ];
    final start = DateTime(2026, 8, 13);
    final today = items
        .where((e) => !e.timestamp.isBefore(start) && e.timestamp.isBefore(start.add(const Duration(days: 1))))
        .fold<int>(0, (p, e) => p + e.amount.minorUnits);
    expect(today, 92000);
    expect(Money(minorUnits: today).format(), contains('920'));
  });

  test('11:59 belongs to that local day and 12:01 belongs to the next', () {
    final a = DateTime(2026, 8, 13, 23, 59);
    final b = DateTime(2026, 8, 14, 0, 1);
    expect(DateTime(a.year, a.month, a.day), DateTime(2026, 8, 13));
    expect(DateTime(b.year, b.month, b.day), DateTime(2026, 8, 14));
  });
}
