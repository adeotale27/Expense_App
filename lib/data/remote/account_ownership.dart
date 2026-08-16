import 'package:drift/drift.dart';

import '../local/app_database.dart';

/// Moves on-device rows from a guest/local user id onto a signed-in account.
///
/// Spends are queried by [userId], not email. Email is stored on the session
/// and on the cloud profile so a new phone can find the same account.
class AccountOwnership {
  static String? normalizeEmail(String? email) {
    final value = email?.trim().toLowerCase();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// Firestore document id for an email lookup (no slashes).
  static String emailLookupId(String email) {
    return normalizeEmail(email)!.replaceAll('/', '_');
  }

  static Future<void> reassign(
    AppDatabase db, {
    required String fromUserId,
    required String toUserId,
  }) async {
    if (fromUserId == toUserId) return;
    await db.transaction(() async {
      await (db.update(db.expenses)..where((t) => t.userId.equals(fromUserId)))
          .write(
        ExpensesCompanion(
          userId: Value(toUserId),
          syncStatus: const Value('pending'),
        ),
      );
      await (db.update(db.categories)..where((t) => t.userId.equals(fromUserId)))
          .write(
        CategoriesCompanion(
          userId: Value(toUserId),
          syncStatus: const Value('pending'),
        ),
      );
      await (db.update(db.places)..where((t) => t.userId.equals(fromUserId)))
          .write(
        PlacesCompanion(
          userId: Value(toUserId),
          syncStatus: const Value('pending'),
        ),
      );
      await (db.update(db.people)..where((t) => t.userId.equals(fromUserId)))
          .write(
        PeopleCompanion(
          userId: Value(toUserId),
          syncStatus: const Value('pending'),
        ),
      );
      await (db.update(db.ledgerEntries)..where((t) => t.userId.equals(fromUserId)))
          .write(
        LedgerEntriesCompanion(
          userId: Value(toUserId),
          syncStatus: const Value('pending'),
        ),
      );
      await (db.update(db.opportunities)..where((t) => t.userId.equals(fromUserId)))
          .write(
        OpportunitiesCompanion(
          userId: Value(toUserId),
          syncStatus: const Value('pending'),
        ),
      );
      await (db.update(db.recurringExpenses)
            ..where((t) => t.userId.equals(fromUserId)))
          .write(
        RecurringExpensesCompanion(
          userId: Value(toUserId),
          syncStatus: const Value('pending'),
        ),
      );
      await (db.update(db.rawLocationPoints)
            ..where((t) => t.userId.equals(fromUserId)))
          .write(RawLocationPointsCompanion(userId: Value(toUserId)));

      final existingSettings = await (db.select(db.settingsRows)
            ..where((t) => t.userId.equals(toUserId)))
          .getSingleOrNull();
      if (existingSettings != null) {
        await (db.delete(db.settingsRows)
              ..where((t) => t.userId.equals(fromUserId)))
            .go();
      } else {
        await (db.update(db.settingsRows)
              ..where((t) => t.userId.equals(fromUserId)))
            .write(
          SettingsRowsCompanion(
            userId: Value(toUserId),
            syncStatus: const Value('pending'),
          ),
        );
      }

      await db.customStatement(
        'UPDATE visit_logs SET user_id = ? WHERE user_id = ?',
        [toUserId, fromUserId],
      );
      await db.customStatement(
        'UPDATE prompt_events SET user_id = ? WHERE user_id = ?',
        [toUserId, fromUserId],
      );
    });
  }
}
