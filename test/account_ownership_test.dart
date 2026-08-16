import 'package:flutter_test/flutter_test.dart';
import 'package:spendping/core/utils/money.dart';
import 'package:spendping/data/local/app_database.dart';
import 'package:spendping/data/remote/account_ownership.dart';
import 'package:spendping/data/repositories/drift_repositories.dart';
import 'package:spendping/data/sync/sync_engine.dart';
import 'package:spendping/domain/entities/entities.dart';
import 'package:spendping/domain/repositories/repositories.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async => db.close());

  test('Google email is normalized for lookup', () {
    expect(AccountOwnership.normalizeEmail(' You@Gmail.COM '), 'you@gmail.com');
    expect(AccountOwnership.emailLookupId('You@Gmail.COM'), 'you@gmail.com');
  });

  test('guest spends move onto the Google account id', () async {
    final now = DateTime.utc(2026, 8, 16, 12);
    final guest = DriftExpenseRepository(db, 'guest-1');
    await guest.upsert(
      Expense(
        id: 'exp-phone',
        userId: 'guest-1',
        amount: Money.fromMajor(80),
        categoryId: 'food',
        timestamp: now,
        createdAt: now,
        updatedAt: now,
        deviceId: 'old-phone',
      ),
    );

    await AccountOwnership.reassign(
      db,
      fromUserId: 'guest-1',
      toUserId: 'google-abc',
    );

    expect((await guest.getById('exp-phone'))!.userId, 'google-abc');
    final google = DriftExpenseRepository(db, 'google-abc');
    final listed = await google.list(const ExpenseQuery());
    expect(listed.single.id, 'exp-phone');
    expect(listed.single.syncStatus.name, 'pending');
  });

  test('new phone pull restores spends for the same account', () async {
    final now = DateTime.utc(2026, 8, 16, 12);
    final cloud = MemoryRemoteStore();
    await cloud.upsert('expenses', 'exp-cloud', {
      'id': 'exp-cloud',
      'userId': 'google-abc',
      'ownerEmail': 'you@gmail.com',
      'amountMinor': 12500,
      'currencyCode': 'INR',
      'categoryId': 'food',
      'timestamp': now.toIso8601String(),
      'source': 'manual',
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'deviceId': 'old-phone',
      'version': 1,
    });

    final restore = SyncEngine(
      db: db,
      userId: 'google-abc',
      ownerEmail: 'you@gmail.com',
      remote: cloud,
    );
    await restore.syncAll();

    final onPhone = DriftExpenseRepository(db, 'google-abc');
    final row = await onPhone.getById('exp-cloud');
    expect(row, isNotNull);
    expect(row!.amount.minorUnits, 12500);
    expect(row.userId, 'google-abc');
  });
}
