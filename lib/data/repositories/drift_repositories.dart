import 'dart:math';

import 'package:drift/drift.dart';

import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/enums.dart';
import '../../domain/repositories/repositories.dart';
import '../local/app_database.dart';
import '../local/mappers.dart';
import '../local/seeds.dart';
import 'intel_store.dart';

class DriftExpenseRepository implements ExpenseRepository {
  DriftExpenseRepository(this.db, this.userId);
  final AppDatabase db;
  final String userId;

  @override
  Stream<List<Expense>> watchRecent({int limit = 50}) {
    final q = (db.select(db.expenses)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
          ..limit(limit))
        .watch();
    return q.map((rows) => rows.map(expenseFromRow).toList());
  }

  @override
  Future<List<Expense>> list(ExpenseQuery query) async {
    final from = query.from;
    final to = query.to;
    final rows = await (db.select(db.expenses)
          ..where((t) {
            var expr = t.userId.equals(userId) & t.deletedAt.isNull();
            if (from != null) expr = expr & t.timestamp.isBiggerOrEqualValue(from);
            if (to != null) expr = expr & t.timestamp.isSmallerOrEqualValue(to);
            if (query.categoryId != null) {
              expr = expr & t.categoryId.equals(query.categoryId!);
            }
            if (query.placeId != null) {
              expr = expr & t.placeId.equals(query.placeId!);
            }
            if (query.paymentMethod != null) {
              expr = expr & t.paymentMethod.equals(query.paymentMethod!.name);
            }
            if (query.minAmountMinor != null) {
              expr =
                  expr & t.amountMinor.isBiggerOrEqualValue(query.minAmountMinor!);
            }
            if (query.maxAmountMinor != null) {
              expr = expr &
                  t.amountMinor.isSmallerOrEqualValue(query.maxAmountMinor!);
            }
            return expr;
          })
          ..orderBy([
            (t) => switch (query.sort) {
                  ExpenseSort.newest => OrderingTerm.desc(t.timestamp),
                  ExpenseSort.oldest => OrderingTerm.asc(t.timestamp),
                  ExpenseSort.highest => OrderingTerm.desc(t.amountMinor),
                  ExpenseSort.lowest => OrderingTerm.asc(t.amountMinor),
                }
          ])
          ..limit(query.limit, offset: query.offset))
        .get();

    var list = rows.map(expenseFromRow).toList();
    final search = query.search?.trim().toLowerCase();
    if (search != null && search.isNotEmpty) {
      list = list.where((e) {
        final hay =
            '${e.merchantName ?? ''} ${e.note ?? ''} ${e.amount.minorUnits}'
                .toLowerCase();
        return hay.contains(search) ||
            e.amount.format().toLowerCase().contains(search);
      }).toList();
    }
    return list;
  }

  @override
  Future<Expense?> getById(String id) async {
    final row = await (db.select(db.expenses)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : expenseFromRow(row);
  }

  @override
  Future<void> upsert(Expense expense) async {
    await db.into(db.expenses).insertOnConflictUpdate(expenseToRow(expense));
  }

  @override
  Future<void> softDelete(String id, DateTime deletedAt) async {
    await (db.update(db.expenses)..where((t) => t.id.equals(id))).write(
      ExpensesCompanion(
        deletedAt: Value(deletedAt),
        updatedAt: Value(deletedAt),
        syncStatus: const Value('pending'),
        version: const Value(1),
      ),
    );
  }

  @override
  Future<int> sumMinor({required DateTime from, required DateTime to}) async {
    final rows = await (db.select(db.expenses)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.timestamp.isBiggerOrEqualValue(from) &
              t.timestamp.isSmallerOrEqualValue(to)))
        .get();
    return rows.fold<int>(0, (p, e) => p + e.amountMinor);
  }

  @override
  Future<Map<String, int>> sumByCategory(
      {required DateTime from, required DateTime to}) async {
    final rows = await (db.select(db.expenses)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.timestamp.isBiggerOrEqualValue(from) &
              t.timestamp.isSmallerOrEqualValue(to)))
        .get();
    final map = <String, int>{};
    for (final r in rows) {
      map[r.categoryId] = (map[r.categoryId] ?? 0) + r.amountMinor;
    }
    return map;
  }

  @override
  Future<List<Expense>> pendingSync() async {
    final rows = await (db.select(db.expenses)
          ..where((t) =>
              t.userId.equals(userId) & t.syncStatus.equals('pending')))
        .get();
    return rows.map(expenseFromRow).toList();
  }
}

class DriftCategoryRepository implements CategoryRepository {
  DriftCategoryRepository(this.db, this.userId, this.deviceId);
  final AppDatabase db;
  final String userId;
  final String deviceId;

  DriftIntelRepository get _intel => DriftIntelRepository(db, userId);

  Future<void> ensureDefaults() async {
    final existing = await (db.select(db.categories)
          ..where((t) => t.userId.equals(userId)))
        .get();
    if (existing.isNotEmpty) return;
    for (final c in buildDefaultCategories(userId: userId, deviceId: deviceId)) {
      await db.into(db.categories).insert(categoryToRow(c));
      await _intel.saveCategoryColor(c.id, c.accentColor);
    }
  }

  Future<List<Category>> _withColors(List<Category> list) async {
    final colors = await _intel.loadCategoryColors();
    return [
      for (final c in list)
        colors.containsKey(c.id) ? c.copyWith(accentColor: colors[c.id]) : c,
    ];
  }

  @override
  Stream<List<Category>> watchActive() {
    return (db.select(db.categories)
          ..where((t) =>
              t.userId.equals(userId) &
              t.isActive.equals(true) &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch()
        .asyncMap((rows) => _withColors(rows.map(categoryFromRow).toList()));
  }

  @override
  Stream<List<Category>> watchAll() {
    return (db.select(db.categories)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch()
        .asyncMap((rows) => _withColors(rows.map(categoryFromRow).toList()));
  }

  @override
  Future<List<Category>> all() async {
    final rows = await (db.select(db.categories)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    return _withColors(rows.map(categoryFromRow).toList());
  }

  @override
  Future<void> upsert(Category category) async {
    await db.into(db.categories).insertOnConflictUpdate(categoryToRow(category));
    await _intel.saveCategoryColor(category.id, category.accentColor);
  }

  @override
  Future<Category?> byName(String name) async {
    final row = await (db.select(db.categories)
          ..where((t) =>
              t.userId.equals(userId) &
              t.name.equals(name) &
              t.deletedAt.isNull()))
        .getSingleOrNull();
    if (row == null) return null;
    final list = await _withColors([categoryFromRow(row)]);
    return list.first;
  }

  @override
  Future<Category?> getById(String id) async {
    final row = await (db.select(db.categories)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    final list = await _withColors([categoryFromRow(row)]);
    return list.first;
  }
}

class DriftPlaceRepository implements PlaceRepository {
  DriftPlaceRepository(this.db, this.userId);
  final AppDatabase db;
  final String userId;

  DriftIntelRepository get _intel => DriftIntelRepository(db, userId);

  Future<List<Place>> _merge(List<Place> list) async {
    final extras = await _intel.loadPlaceIntel();
    return [for (final p in list) mergePlaceIntel(p, extras)];
  }

  Future<Place?> _mergeOne(Place? place) async {
    if (place == null) return null;
    final extras = await _intel.loadPlaceIntel();
    return mergePlaceIntel(place, extras);
  }

  @override
  Stream<List<Place>> watchAll() {
    return (db.select(db.places)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.totalSpendMinor)]))
        .watch()
        .asyncMap((rows) async {
      final merged = await _merge(rows.map(placeFromRow).toList());
      return merged.where((p) => !p.forgotten).toList();
    });
  }

  @override
  Future<List<Place>> all() async {
    final rows = await (db.select(db.places)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull()))
        .get();
    final merged = await _merge(rows.map(placeFromRow).toList());
    return merged.where((p) => !p.forgotten).toList();
  }

  @override
  Future<Place?> getById(String id) async {
    final row =
        await (db.select(db.places)..where((t) => t.id.equals(id))).getSingleOrNull();
    return _mergeOne(row == null ? null : placeFromRow(row));
  }

  @override
  Future<Place?> findNearby(double lat, double lng, {double maxMeters = 150}) async {
    final allPlaces = await all();
    Place? best;
    var bestD = maxMeters;
    for (final p in allPlaces) {
      final d = haversineMeters(lat, lng, p.latitude, p.longitude);
      if (d <= p.radius && d <= bestD) {
        best = p;
        bestD = d;
      }
    }
    return best;
  }

  @override
  Future<void> upsert(Place place) async {
    await db.into(db.places).insertOnConflictUpdate(placeToRow(place));
    await _intel.savePlaceIntel(place);
  }

  @override
  Future<void> forget(String id, DateTime at) async {
    final existing = await getById(id);
    if (existing == null) return;
    await upsert(existing.copyWith(forgotten: true, geofenceEnabled: false, updatedAt: at));
  }
}

class DriftPersonRepository implements PersonRepository {
  DriftPersonRepository(this.db, this.userId);
  final AppDatabase db;
  final String userId;

  DriftIntelRepository get _intel => DriftIntelRepository(db, userId);

  Future<List<Person>> _merge(List<Person> list) async {
    final extras = await _intel.loadPeopleIntel();
    return [
      for (final p in list)
        extras.containsKey(p.id)
            ? p.copyWith(archived: extras[p.id]!.$1, photoPath: extras[p.id]!.$2)
            : p,
    ];
  }

  @override
  Stream<List<Person>> watchAll() {
    return (db.select(db.people)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch()
        .asyncMap((rows) async {
      final merged = await _merge(rows.map(personFromRow).toList());
      return merged.where((p) => !p.archived).toList();
    });
  }

  @override
  Future<Person?> getById(String id) async {
    final row =
        await (db.select(db.people)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final merged = await _merge([personFromRow(row)]);
    return merged.first;
  }

  @override
  Future<void> upsert(Person person) async {
    await db.into(db.people).insertOnConflictUpdate(personToRow(person));
    await _intel.savePersonIntel(person);
  }

  @override
  Future<void> softDelete(String id, DateTime deletedAt) async {
    await (db.update(db.people)..where((t) => t.id.equals(id))).write(
      PeopleCompanion(
        deletedAt: Value(deletedAt),
        updatedAt: Value(deletedAt),
        syncStatus: const Value('pending'),
      ),
    );
  }
}

class DriftLedgerRepository implements LedgerRepository {
  DriftLedgerRepository(this.db, this.userId);
  final AppDatabase db;
  final String userId;

  @override
  Stream<List<LedgerEntry>> watchForPerson(String personId) {
    return (db.select(db.ledgerEntries)
          ..where((t) =>
              t.userId.equals(userId) &
              t.personId.equals(personId) &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch()
        .map((rows) => rows.map(ledgerFromRow).toList());
  }

  @override
  Future<List<LedgerEntry>> all() async {
    final rows = await (db.select(db.ledgerEntries)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull()))
        .get();
    return rows.map(ledgerFromRow).toList();
  }

  @override
  Future<void> add(LedgerEntry entry) async {
    await db.into(db.ledgerEntries).insert(ledgerToRow(entry));
  }

  @override
  Future<int> balanceMinorFor(String personId) async {
    final rows = await (db.select(db.ledgerEntries)
          ..where((t) =>
              t.userId.equals(userId) &
              t.personId.equals(personId) &
              t.deletedAt.isNull()))
        .get();
    return rows.map(ledgerFromRow).fold<int>(0, (p, e) => p + e.signedMinor);
  }
}

class DriftOpportunityRepository implements OpportunityRepository {
  DriftOpportunityRepository(this.db, this.userId);
  final AppDatabase db;
  final String userId;

  @override
  Stream<List<ExpenseOpportunity>> watchPending() {
    return (db.select(db.opportunities)
          ..where((t) =>
              t.userId.equals(userId) & t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.desc(t.detectedAt)]))
        .watch()
        .map((rows) => rows.map(opportunityFromRow).toList());
  }

  @override
  Future<List<ExpenseOpportunity>> pending() async {
    final rows = await (db.select(db.opportunities)
          ..where((t) =>
              t.userId.equals(userId) & t.status.equals('pending')))
        .get();
    return rows.map(opportunityFromRow).toList();
  }

  @override
  Future<void> upsert(ExpenseOpportunity opportunity) async {
    await db
        .into(db.opportunities)
        .insertOnConflictUpdate(opportunityToRow(opportunity));
  }

  @override
  Future<bool> hasOpenForPlaceSince(String placeId, DateTime since) async {
    final row = await (db.select(db.opportunities)
          ..where((t) =>
              t.userId.equals(userId) &
              t.placeId.equals(placeId) &
              t.detectedAt.isBiggerOrEqualValue(since) &
              t.status.isIn(['pending', 'expenseAdded'])))
        .getSingleOrNull();
    return row != null;
  }
}

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this.db);
  final AppDatabase db;

  @override
  Future<AppSettings> get(String userId) async {
    final row = await (db.select(db.settingsRows)
          ..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null) return AppSettings(userId: userId);
    return settingsFromJson(userId, row.json);
  }

  @override
  Future<void> save(AppSettings settings) async {
    await db.into(db.settingsRows).insertOnConflictUpdate(
          SettingsRowsCompanion(
            userId: Value(settings.userId),
            json: Value(settingsToJson(settings)),
            updatedAt: Value(utcNow()),
            syncStatus: const Value('pending'),
          ),
        );
  }

  @override
  Stream<AppSettings> watch(String userId) {
    return (db.select(db.settingsRows)..where((t) => t.userId.equals(userId)))
        .watchSingleOrNull()
        .map((row) => row == null
            ? AppSettings(userId: userId)
            : settingsFromJson(userId, row.json));
  }
}

class DriftRecurringRepository implements RecurringRepository {
  DriftRecurringRepository(this.db, this.userId);
  final AppDatabase db;
  final String userId;

  @override
  Stream<List<RecurringExpense>> watchActive() {
    return (db.select(db.recurringExpenses)
          ..where((t) =>
              t.userId.equals(userId) &
              t.isActive.equals(true) &
              t.deletedAt.isNull()))
        .watch()
        .map(
          (rows) => rows
              .map(
                (r) => RecurringExpense(
                  id: r.id,
                  userId: r.userId,
                  name: r.name,
                  amount: Money(
                    minorUnits: r.amountMinor,
                    currencyCode: r.currencyCode,
                  ),
                  frequency: r.frequency,
                  categoryId: r.categoryId,
                  nextExpectedDate: r.nextExpectedDate,
                  isActive: r.isActive,
                  createdAt: r.createdAt,
                  updatedAt: r.updatedAt,
                  deletedAt: r.deletedAt,
                  syncStatus: SyncStatus.values.byName(r.syncStatus),
                  deviceId: r.deviceId,
                  version: r.version,
                ),
              )
              .toList(),
        );
  }

  @override
  Future<void> upsert(RecurringExpense item) async {
    await db.into(db.recurringExpenses).insertOnConflictUpdate(
          RecurringExpensesCompanion(
            id: Value(item.id),
            userId: Value(item.userId),
            name: Value(item.name),
            amountMinor: Value(item.amount.minorUnits),
            currencyCode: Value(item.amount.currencyCode),
            frequency: Value(item.frequency),
            categoryId: Value(item.categoryId),
            nextExpectedDate: Value(item.nextExpectedDate),
            isActive: Value(item.isActive),
            createdAt: Value(item.createdAt),
            updatedAt: Value(item.updatedAt),
            deletedAt: Value(item.deletedAt),
            syncStatus: Value(item.syncStatus.name),
            deviceId: Value(item.deviceId),
            version: Value(item.version),
          ),
        );
  }
}

double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371000.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _rad(double d) => d * pi / 180.0;
