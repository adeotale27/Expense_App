import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Expenses,
    Categories,
    Places,
    People,
    LedgerEntries,
    Opportunities,
    RecurringExpenses,
    SettingsRows,
    LocalAccounts,
    RawLocationPoints,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());

  static Future<AppDatabase> file() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'spendping.sqlite'));
    return AppDatabase(NativeDatabase.createInBackground(file));
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
            'CREATE INDEX IF NOT EXISTS expenses_user_time ON expenses(user_id, timestamp);',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS expenses_user_cat ON expenses(user_id, category_id);',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS ledger_person ON ledger_entries(person_id, date);',
          );
        },
      );
}
