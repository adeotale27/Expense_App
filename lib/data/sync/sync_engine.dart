import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';

import '../local/app_database.dart';
import '../local/mappers.dart';
import '../remote/account_ownership.dart';

abstract class RemoteStore {
  Future<void> upsert(String collection, String id, Map<String, dynamic> data);
  Future<Map<String, Map<String, dynamic>>> fetchAll(String collection);
}

class MemoryRemoteStore implements RemoteStore {
  final Map<String, Map<String, Map<String, dynamic>>> _data = {};

  @override
  Future<void> upsert(String collection, String id, Map<String, dynamic> data) async {
    _data.putIfAbsent(collection, () => {});
    _data[collection]![id] = data;
  }

  @override
  Future<Map<String, Map<String, dynamic>>> fetchAll(String collection) async {
    return Map.of(_data[collection] ?? {});
  }
}

class FirestoreRemoteStore implements RemoteStore {
  FirestoreRemoteStore(this.userId);
  final String userId;

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      FirebaseFirestore.instance.collection('users').doc(userId).collection(name);

  @override
  Future<void> upsert(String collection, String id, Map<String, dynamic> data) async {
    await _col(collection).doc(id).set(data, SetOptions(merge: true));
  }

  @override
  Future<Map<String, Map<String, dynamic>>> fetchAll(String collection) async {
    final snap = await _col(collection).get();
    return {for (final d in snap.docs) d.id: d.data()};
  }
}

class SyncEngine {
  SyncEngine({
    required this.db,
    required this.userId,
    required this.remote,
    this.ownerEmail,
  });

  final AppDatabase db;
  final String userId;
  final RemoteStore remote;
  final String? ownerEmail;

  Map<String, dynamic> get _accountFields => {
        'userId': userId,
        'ownerEmail': AccountOwnership.normalizeEmail(ownerEmail),
      };

  bool running = false;
  String status = 'idle';

  Future<void> syncAll() async {
    if (running) return;
    running = true;
    status = 'syncing';
    try {
      await _pushExpenses();
      await _pushPlaces();
      await _pushPeople();
      await _pushLedger();
      await _pushCategories();
      await _pullExpenses();
      await _pullPlaces();
      await _pullPeople();
      await _pullLedger();
      await _pullCategories();
      status = 'synced';
    } catch (e) {
      status = 'error';
      rethrow;
    } finally {
      running = false;
    }
  }

  Future<void> _pushExpenses() async {
    final rows = await (db.select(db.expenses)
          ..where((t) => t.userId.equals(userId) & t.syncStatus.equals('pending')))
        .get();
    for (final row in rows) {
      final e = expenseFromRow(row);
      await remote.upsert('expenses', e.id, {
        ..._accountFields,
        'id': e.id,
        'amountMinor': e.amount.minorUnits,
        'currencyCode': e.amount.currencyCode,
        'categoryId': e.categoryId,
        'merchantName': e.merchantName,
        'placeId': e.placeId,
        'paymentMethod': e.paymentMethod.name,
        'note': e.note,
        'timestamp': e.timestamp.toIso8601String(),
        'source': e.source.name,
        'opportunityId': e.opportunityId,
        'createdAt': e.createdAt.toIso8601String(),
        'updatedAt': e.updatedAt.toIso8601String(),
        'deletedAt': e.deletedAt?.toIso8601String(),
        'deviceId': e.deviceId,
        'version': e.version,
      });
      await (db.update(db.expenses)..where((t) => t.id.equals(e.id))).write(
        const ExpensesCompanion(syncStatus: Value('synced')),
      );
    }
  }

  Future<void> _pushPlaces() async {
    final rows = await (db.select(db.places)
          ..where((t) => t.userId.equals(userId) & t.syncStatus.equals('pending')))
        .get();
    for (final row in rows) {
      final p = placeFromRow(row);
      await remote.upsert('places', p.id, {
        ..._accountFields,
        'id': p.id,
        'name': p.name,
        'type': p.type.name,
        'latitude': p.latitude,
        'longitude': p.longitude,
        'radius': p.radius,
        'visitCount': p.visitCount,
        'totalSpendMinor': p.totalSpendMinor,
        'lastVisitedAt': p.lastVisitedAt?.toIso8601String(),
        'createdAt': p.createdAt.toIso8601String(),
        'updatedAt': p.updatedAt.toIso8601String(),
        'deletedAt': p.deletedAt?.toIso8601String(),
        'deviceId': p.deviceId,
        'version': p.version,
      });
      await (db.update(db.places)..where((t) => t.id.equals(p.id))).write(
        const PlacesCompanion(syncStatus: Value('synced')),
      );
    }
  }

  Future<void> _pushPeople() async {
    final rows = await (db.select(db.people)
          ..where((t) => t.userId.equals(userId) & t.syncStatus.equals('pending')))
        .get();
    for (final row in rows) {
      final p = personFromRow(row);
      await remote.upsert('people', p.id, {
        ..._accountFields,
        'id': p.id,
        'name': p.name,
        'phone': p.phone,
        'note': p.note,
        'createdAt': p.createdAt.toIso8601String(),
        'updatedAt': p.updatedAt.toIso8601String(),
        'deletedAt': p.deletedAt?.toIso8601String(),
        'deviceId': p.deviceId,
        'version': p.version,
      });
      await (db.update(db.people)..where((t) => t.id.equals(p.id))).write(
        const PeopleCompanion(syncStatus: Value('synced')),
      );
    }
  }

  Future<void> _pushLedger() async {
    final rows = await (db.select(db.ledgerEntries)
          ..where((t) => t.userId.equals(userId) & t.syncStatus.equals('pending')))
        .get();
    for (final row in rows) {
      final e = ledgerFromRow(row);
      await remote.upsert('ledger', e.id, {
        ..._accountFields,
        'id': e.id,
        'personId': e.personId,
        'amountMinor': e.amount.minorUnits,
        'currencyCode': e.amount.currencyCode,
        'direction': e.direction.name,
        'type': e.type.name,
        'date': e.date.toIso8601String(),
        'note': e.note,
        'relatedExpenseId': e.relatedExpenseId,
        'createdAt': e.createdAt.toIso8601String(),
        'updatedAt': e.updatedAt.toIso8601String(),
        'deletedAt': e.deletedAt?.toIso8601String(),
        'deviceId': e.deviceId,
        'version': e.version,
      });
      await (db.update(db.ledgerEntries)..where((t) => t.id.equals(e.id))).write(
        const LedgerEntriesCompanion(syncStatus: Value('synced')),
      );
    }
  }

  Future<void> _pushCategories() async {
    final rows = await (db.select(db.categories)
          ..where((t) => t.userId.equals(userId) & t.syncStatus.equals('pending')))
        .get();
    for (final row in rows) {
      final c = categoryFromRow(row);
      await remote.upsert('categories', c.id, {
        ..._accountFields,
        'id': c.id,
        'name': c.name,
        'icon': c.icon,
        'isDefault': c.isDefault,
        'isActive': c.isActive,
        'sortOrder': c.sortOrder,
        'createdAt': c.createdAt.toIso8601String(),
        'updatedAt': c.updatedAt.toIso8601String(),
        'deletedAt': c.deletedAt?.toIso8601String(),
        'deviceId': c.deviceId,
        'version': c.version,
      });
      await (db.update(db.categories)..where((t) => t.id.equals(c.id))).write(
        const CategoriesCompanion(syncStatus: Value('synced')),
      );
    }
  }

  DateTime _parseDate(Object? value) => DateTime.parse(value as String);

  DateTime? _parseDateOrNull(Object? value) =>
      value == null ? null : DateTime.parse(value as String);

  bool _shouldApply(DateTime? localUpdated, DateTime remoteUpdated) {
    return localUpdated == null || localUpdated.isBefore(remoteUpdated);
  }

  Future<void> _pullExpenses() async {
    final remoteRows = await remote.fetchAll('expenses');
    for (final entry in remoteRows.entries) {
      final data = entry.value;
      final existing = await (db.select(db.expenses)
            ..where((t) => t.id.equals(entry.key)))
          .getSingleOrNull();
      final remoteUpdated = _parseDate(data['updatedAt']);
      if (_shouldApply(existing?.updatedAt, remoteUpdated)) {
        await db.into(db.expenses).insertOnConflictUpdate(
              ExpensesCompanion(
                id: Value(entry.key),
                userId: Value(userId),
                amountMinor: Value(data['amountMinor'] as int),
                currencyCode: Value(data['currencyCode'] as String? ?? 'INR'),
                categoryId: Value(data['categoryId'] as String),
                merchantName: Value(data['merchantName'] as String?),
                placeId: Value(data['placeId'] as String?),
                paymentMethod: Value(data['paymentMethod'] as String? ?? 'notSpecified'),
                note: Value(data['note'] as String?),
                timestamp: Value(_parseDate(data['timestamp'])),
                source: Value(data['source'] as String? ?? 'manual'),
                opportunityId: Value(data['opportunityId'] as String?),
                createdAt: Value(_parseDate(data['createdAt'])),
                updatedAt: Value(remoteUpdated),
                deletedAt: Value(_parseDateOrNull(data['deletedAt'])),
                syncStatus: const Value('synced'),
                deviceId: Value(data['deviceId'] as String? ?? ''),
                version: Value(data['version'] as int? ?? 1),
              ),
            );
      }
    }
  }

  Future<void> _pullPlaces() async {
    final remoteRows = await remote.fetchAll('places');
    for (final entry in remoteRows.entries) {
      final data = entry.value;
      final existing = await (db.select(db.places)
            ..where((t) => t.id.equals(entry.key)))
          .getSingleOrNull();
      final remoteUpdated = _parseDate(data['updatedAt']);
      if (_shouldApply(existing?.updatedAt, remoteUpdated)) {
        await db.into(db.places).insertOnConflictUpdate(
              PlacesCompanion(
                id: Value(entry.key),
                userId: Value(userId),
                name: Value(data['name'] as String),
                type: Value(data['type'] as String? ?? 'unknown'),
                latitude: Value((data['latitude'] as num).toDouble()),
                longitude: Value((data['longitude'] as num).toDouble()),
                radius: Value((data['radius'] as num?)?.toDouble() ?? 80),
                visitCount: Value(data['visitCount'] as int? ?? 0),
                totalSpendMinor: Value(data['totalSpendMinor'] as int? ?? 0),
                lastVisitedAt: Value(_parseDateOrNull(data['lastVisitedAt'])),
                createdAt: Value(_parseDate(data['createdAt'])),
                updatedAt: Value(remoteUpdated),
                deletedAt: Value(_parseDateOrNull(data['deletedAt'])),
                syncStatus: const Value('synced'),
                deviceId: Value(data['deviceId'] as String? ?? ''),
                version: Value(data['version'] as int? ?? 1),
              ),
            );
      }
    }
  }

  Future<void> _pullPeople() async {
    final remoteRows = await remote.fetchAll('people');
    for (final entry in remoteRows.entries) {
      final data = entry.value;
      final existing = await (db.select(db.people)
            ..where((t) => t.id.equals(entry.key)))
          .getSingleOrNull();
      final remoteUpdated = _parseDate(data['updatedAt']);
      if (_shouldApply(existing?.updatedAt, remoteUpdated)) {
        await db.into(db.people).insertOnConflictUpdate(
              PeopleCompanion(
                id: Value(entry.key),
                userId: Value(userId),
                name: Value(data['name'] as String),
                phone: Value(data['phone'] as String?),
                note: Value(data['note'] as String?),
                createdAt: Value(_parseDate(data['createdAt'])),
                updatedAt: Value(remoteUpdated),
                deletedAt: Value(_parseDateOrNull(data['deletedAt'])),
                syncStatus: const Value('synced'),
                deviceId: Value(data['deviceId'] as String? ?? ''),
                version: Value(data['version'] as int? ?? 1),
              ),
            );
      }
    }
  }

  Future<void> _pullLedger() async {
    final remoteRows = await remote.fetchAll('ledger');
    for (final entry in remoteRows.entries) {
      final data = entry.value;
      final existing = await (db.select(db.ledgerEntries)
            ..where((t) => t.id.equals(entry.key)))
          .getSingleOrNull();
      final remoteUpdated = _parseDate(data['updatedAt']);
      if (_shouldApply(existing?.updatedAt, remoteUpdated)) {
        await db.into(db.ledgerEntries).insertOnConflictUpdate(
              LedgerEntriesCompanion(
                id: Value(entry.key),
                userId: Value(userId),
                personId: Value(data['personId'] as String),
                amountMinor: Value(data['amountMinor'] as int),
                currencyCode: Value(data['currencyCode'] as String? ?? 'INR'),
                direction: Value(data['direction'] as String),
                type: Value(data['type'] as String),
                date: Value(_parseDate(data['date'])),
                note: Value(data['note'] as String?),
                relatedExpenseId: Value(data['relatedExpenseId'] as String?),
                createdAt: Value(_parseDate(data['createdAt'])),
                updatedAt: Value(remoteUpdated),
                deletedAt: Value(_parseDateOrNull(data['deletedAt'])),
                syncStatus: const Value('synced'),
                deviceId: Value(data['deviceId'] as String? ?? ''),
                version: Value(data['version'] as int? ?? 1),
              ),
            );
      }
    }
  }

  Future<void> _pullCategories() async {
    final remoteRows = await remote.fetchAll('categories');
    for (final entry in remoteRows.entries) {
      final data = entry.value;
      final existing = await (db.select(db.categories)
            ..where((t) => t.id.equals(entry.key)))
          .getSingleOrNull();
      final remoteUpdated = _parseDate(data['updatedAt']);
      if (_shouldApply(existing?.updatedAt, remoteUpdated)) {
        await db.into(db.categories).insertOnConflictUpdate(
              CategoriesCompanion(
                id: Value(entry.key),
                userId: Value(userId),
                name: Value(data['name'] as String),
                icon: Value(data['icon'] as String),
                isDefault: Value(data['isDefault'] as bool? ?? false),
                isActive: Value(data['isActive'] as bool? ?? true),
                sortOrder: Value(data['sortOrder'] as int? ?? 0),
                createdAt: Value(_parseDate(data['createdAt'])),
                updatedAt: Value(remoteUpdated),
                deletedAt: Value(_parseDateOrNull(data['deletedAt'])),
                syncStatus: const Value('synced'),
                deviceId: Value(data['deviceId'] as String? ?? ''),
                version: Value(data['version'] as int? ?? 1),
              ),
            );
      }
    }
  }
}
