import 'package:flutter_test/flutter_test.dart';
import 'package:spendping/core/utils/money.dart';
import 'package:spendping/data/local/app_database.dart';
import 'package:spendping/data/repositories/drift_repositories.dart';
import 'package:spendping/data/sync/sync_engine.dart';
import 'package:spendping/domain/entities/entities.dart';

void main() {
  late AppDatabase db;
  late DriftExpenseRepository repo;
  late SyncEngine sync;
  late MemoryRemoteStore remote;

  setUp(() {
    db = AppDatabase.memory();
    repo = DriftExpenseRepository(db, 'u1');
    remote = MemoryRemoteStore();
    sync = SyncEngine(db: db, userId: 'u1', remote: remote);
  });

  tearDown(() async => db.close());

  test('offline create then sync uploads once without duplicates', () async {
    final now = DateTime.utc(2026, 8, 13, 12);
    final expense = Expense(
      id: 'exp-1',
      userId: 'u1',
      amount: Money.fromMajor(250),
      categoryId: 'food',
      timestamp: now,
      createdAt: now,
      updatedAt: now,
      deviceId: 'd1',
    );
    await repo.upsert(expense);
    expect((await repo.getById('exp-1'))!.amount.minorUnits, 25000);
    await sync.syncAll();
    final remoteRows = await remote.fetchAll('expenses');
    expect(remoteRows.length, 1);
    expect(remoteRows['exp-1']?['amountMinor'], 25000);
    await sync.syncAll();
    expect((await remote.fetchAll('expenses')).length, 1);
  });

  test('soft delete stays until synced', () async {
    final now = DateTime.utc(2026, 8, 13, 12);
    await repo.upsert(
      Expense(
        id: 'exp-2',
        userId: 'u1',
        amount: Money.fromMajor(100),
        categoryId: 'food',
        timestamp: now,
        createdAt: now,
        updatedAt: now,
        deviceId: 'd1',
      ),
    );
    await repo.softDelete('exp-2', now);
    final pending = await repo.pendingSync();
    expect(pending.single.deletedAt, isNotNull);
  });
}
