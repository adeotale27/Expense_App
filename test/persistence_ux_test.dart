import 'package:flutter_test/flutter_test.dart';
import 'package:spendping/core/utils/money.dart';
import 'package:spendping/data/local/app_database.dart';
import 'package:spendping/data/repositories/drift_repositories.dart';
import 'package:spendping/domain/entities/entities.dart';
import 'package:spendping/domain/enums/enums.dart';
import 'package:spendping/domain/repositories/repositories.dart';

void main() {
  late AppDatabase db;
  late DriftExpenseRepository expenses;
  late DriftCategoryRepository categories;
  late DriftPersonRepository people;
  late DriftLedgerRepository ledger;
  late DriftPlaceRepository places;

  setUp(() {
    db = AppDatabase.memory();
    expenses = DriftExpenseRepository(db, 'u');
    categories = DriftCategoryRepository(db, 'u', 'd');
    people = DriftPersonRepository(db, 'u');
    ledger = DriftLedgerRepository(db, 'u');
    places = DriftPlaceRepository(db, 'u');
  });

  tearDown(() async => db.close());

  final now = DateTime.utc(2026, 8, 16);

  test('expense create edit delete', () async {
    await categories.ensureDefaults();
    final cat = (await categories.all()).first;
    final e = Expense(
      id: 'e1',
      userId: 'u',
      amount: Money(minorUnits: 45000),
      categoryId: cat.id,
      paymentMethod: PaymentMethod.upi,
      timestamp: now,
      createdAt: now,
      updatedAt: now,
      deviceId: 'd',
    );
    await expenses.upsert(e);
    expect((await expenses.getById('e1'))?.amount.minorUnits, 45000);
    await expenses.upsert(e.copyWith(amount: Money(minorUnits: 50000), updatedAt: now));
    expect((await expenses.getById('e1'))?.amount.minorUnits, 50000);
    await expenses.softDelete('e1', now);
    final listed = await expenses.list(const ExpenseQuery());
    expect(listed.where((x) => x.id == 'e1'), isEmpty);
  });

  test('category hide restore keeps expense', () async {
    await categories.ensureDefaults();
    final cat = (await categories.all()).firstWhere((c) => c.name == 'Food');
    await expenses.upsert(
      Expense(
        id: 'e-food',
        userId: 'u',
        amount: Money(minorUnits: 10000),
        categoryId: cat.id,
        timestamp: now,
        createdAt: now,
        updatedAt: now,
        deviceId: 'd',
      ),
    );
    await categories.upsert(cat.copyWith(isActive: false, updatedAt: now));
    final active = await categories.watchActive().first;
    expect(active.any((c) => c.id == cat.id), isFalse);
    final hidden = await categories.all();
    expect(hidden.any((c) => c.id == cat.id && !c.isActive), isTrue);
    expect((await expenses.getById('e-food'))?.categoryId, cat.id);
    await categories.upsert(cat.copyWith(isActive: true, updatedAt: now));
    expect((await categories.watchActive().first).any((c) => c.id == cat.id), isTrue);
  });

  test('people add edit borrow lend settle', () async {
    final person = Person(
      id: 'rahul',
      userId: 'u',
      name: 'Rahul',
      createdAt: now,
      updatedAt: now,
      deviceId: 'd',
    );
    await people.upsert(person);
    await people.upsert(person.copyWith(name: 'Rahul S', updatedAt: now));
    expect((await people.getById('rahul'))?.name, 'Rahul S');
    await ledger.add(
      LedgerEntry(
        id: 'l1',
        userId: 'u',
        personId: 'rahul',
        amount: Money(minorUnits: 85000),
        direction: LedgerDirection.owedByUser,
        type: LedgerType.borrowed,
        date: now,
        createdAt: now,
        updatedAt: now,
        deviceId: 'd',
      ),
    );
    expect(await ledger.balanceMinorFor('rahul'), -85000);
    await ledger.add(
      LedgerEntry(
        id: 'l2',
        userId: 'u',
        personId: 'rahul',
        amount: Money(minorUnits: 85000),
        direction: LedgerDirection.owedByUser,
        type: LedgerType.settlement,
        date: now,
        createdAt: now,
        updatedAt: now,
        deviceId: 'd',
      ),
    );
    expect(await ledger.balanceMinorFor('rahul'), 0);
  });

  test('given to a friend on a chosen date', () async {
    final person = Person(
      id: 'neha',
      userId: 'u',
      name: 'Neha',
      createdAt: now,
      updatedAt: now,
      deviceId: 'd',
    );
    await people.upsert(person);
    final when = DateTime.utc(2026, 8, 10, 12);
    await ledger.add(
      LedgerEntry(
        id: 'g1',
        userId: 'u',
        personId: 'neha',
        amount: Money(minorUnits: 40000),
        direction: LedgerDirection.owedToUser,
        type: LedgerType.lent,
        date: when,
        note: 'Given',
        createdAt: now,
        updatedAt: now,
        deviceId: 'd',
      ),
    );
    expect(await ledger.balanceMinorFor('neha'), 40000);
    final rows = await ledger.watchForPerson('neha').first;
    expect(rows.single.date.year, 2026);
    expect(rows.single.date.month, 8);
    expect(rows.single.date.day, 10);
    expect(rows.single.note, 'Given');
  });

  test('places remember rename forget', () async {
    final place = Place(
      id: 'mall',
      userId: 'u',
      name: 'Phoenix Mall',
      type: PlaceType.shopping,
      latitude: 18.5,
      longitude: 73.8,
      createdAt: now,
      updatedAt: now,
      deviceId: 'd',
    );
    await places.upsert(place);
    await places.upsert(place.copyWith(name: 'Phoenix', userConfirmedName: true, updatedAt: now));
    expect((await places.getById('mall'))?.name, 'Phoenix');
    await places.forget('mall', now);
    expect((await places.all()).any((p) => p.id == 'mall'), isFalse);
    expect((await places.getById('mall'))?.forgotten, isTrue);
  });
}
