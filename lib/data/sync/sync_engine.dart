import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';

import '../local/app_database.dart';
import '../local/mappers.dart';
import '../remote/auth_service.dart';

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
  });

  final AppDatabase db;
  final String userId;
  final RemoteStore remote;

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
        'id': e.id,
        'userId': e.userId,
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
        'id': p.id,
        'userId': p.userId,
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
        'id': p.id,
        'userId': p.userId,
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
        'id': e.id,
        'userId': e.userId,
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
        'id': c.id,
        'userId': c.userId,
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

  Future<void> _pullExpenses() async {
    if (!FirebaseBootstrap.available) return;
    final remoteRows = await remote.fetchAll('expenses');
    for (final entry in remoteRows.entries) {
      final data = entry.value;
      final existing = await (db.select(db.expenses)
            ..where((t) => t.id.equals(entry.key)))
          .getSingleOrNull();
      final remoteUpdated = DateTime.parse(data['updatedAt'] as String);
      if (existing == null || existing.updatedAt.isBefore(remoteUpdated)) {
        await db.into(db.expenses).insertOnConflictUpdate(
              ExpensesCompanion(
                id: Value(entry.key),
                userId: Value(data['userId'] as String),
                amountMinor: Value(data['amountMinor'] as int),
                currencyCode: Value(data['currencyCode'] as String? ?? 'INR'),
                categoryId: Value(data['categoryId'] as String),
                merchantName: Value(data['merchantName'] as String?),
                placeId: Value(data['placeId'] as String?),
                paymentMethod: Value(data['paymentMethod'] as String? ?? 'notSpecified'),
                note: Value(data['note'] as String?),
                timestamp: Value(DateTime.parse(data['timestamp'] as String)),
                source: Value(data['source'] as String? ?? 'manual'),
                opportunityId: Value(data['opportunityId'] as String?),
                createdAt: Value(DateTime.parse(data['createdAt'] as String)),
                updatedAt: Value(remoteUpdated),
                deletedAt: Value(
                  data['deletedAt'] == null
                      ? null
                      : DateTime.parse(data['deletedAt'] as String),
                ),
                syncStatus: const Value('synced'),
                deviceId: Value(data['deviceId'] as String? ?? ''),
                version: Value(data['version'] as int? ?? 1),
              ),
            );
      }
    }
  }
}
