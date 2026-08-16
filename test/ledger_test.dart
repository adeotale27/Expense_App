import 'package:flutter_test/flutter_test.dart';
import 'package:spendping/core/utils/money.dart';
import 'package:spendping/domain/entities/entities.dart';
import 'package:spendping/domain/enums/enums.dart';

LedgerEntry entry({
  required LedgerType type,
  required LedgerDirection direction,
  required int minor,
}) {
  final now = DateTime.utc(2026, 8, 13);
  return LedgerEntry(
    id: 'x',
    userId: 'u',
    personId: 'rahul',
    amount: Money(minorUnits: minor),
    direction: direction,
    type: type,
    date: now,
    createdAt: now,
    updatedAt: now,
    deviceId: 'd',
  );
}

void main() {
  test('borrow then partial repayment', () {
    final borrowed = entry(
      type: LedgerType.borrowed,
      direction: LedgerDirection.owedByUser,
      minor: 500000,
    );
    final repay = entry(
      type: LedgerType.repayment,
      direction: LedgerDirection.owedByUser,
      minor: 200000,
    );
    final balance = borrowed.signedMinor + repay.signedMinor;
    expect(balance, -300000);
  });

  test('lend creates positive balance', () {
    final lent = entry(
      type: LedgerType.lent,
      direction: LedgerDirection.owedToUser,
      minor: 200000,
    );
    expect(lent.signedMinor, 200000);
  });

  test('settle up reduces what they owe', () {
    final lent = entry(
      type: LedgerType.lent,
      direction: LedgerDirection.owedToUser,
      minor: 200000,
    );
    final settle = entry(
      type: LedgerType.settlement,
      direction: LedgerDirection.owedToUser,
      minor: 200000,
    );
    expect(lent.signedMinor + settle.signedMinor, 0);
  });

  test('settle up reduces what you owe', () {
    final borrowed = entry(
      type: LedgerType.borrowed,
      direction: LedgerDirection.owedByUser,
      minor: 150000,
    );
    final settle = entry(
      type: LedgerType.settlement,
      direction: LedgerDirection.owedByUser,
      minor: 150000,
    );
    expect(borrowed.signedMinor + settle.signedMinor, 0);
  });
}
