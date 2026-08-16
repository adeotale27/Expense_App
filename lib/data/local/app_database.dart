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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _indexes();
          await _intelTables();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await _intelTables();
          }
        },
      );

  Future<void> _indexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS expenses_user_time ON expenses(user_id, timestamp);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS expenses_user_cat ON expenses(user_id, category_id);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS ledger_person ON ledger_entries(person_id, date);',
    );
  }

  Future<void> _intelTables() async {
    await customStatement('''
CREATE TABLE IF NOT EXISTS visit_logs (
  id TEXT PRIMARY KEY NOT NULL,
  user_id TEXT NOT NULL,
  place_id TEXT NOT NULL,
  started_at INTEGER NOT NULL,
  ended_at INTEGER NOT NULL,
  duration_seconds INTEGER NOT NULL,
  hour_of_day INTEGER NOT NULL,
  weekday INTEGER NOT NULL,
  pass_through INTEGER NOT NULL DEFAULT 0
);
''');
    await customStatement('''
CREATE TABLE IF NOT EXISTS prompt_events (
  id TEXT PRIMARY KEY NOT NULL,
  user_id TEXT NOT NULL,
  kind TEXT NOT NULL,
  place_id TEXT,
  created_at INTEGER NOT NULL,
  response TEXT
);
''');
    await customStatement('''
CREATE TABLE IF NOT EXISTS place_intel (
  place_id TEXT PRIMARY KEY NOT NULL,
  first_visited_at INTEGER,
  confidence INTEGER NOT NULL DEFAULT 0,
  user_confirmed INTEGER NOT NULL DEFAULT 0,
  geofence_enabled INTEGER NOT NULL DEFAULT 0,
  forgotten INTEGER NOT NULL DEFAULT 0
);
''');
    await customStatement('''
CREATE TABLE IF NOT EXISTS people_intel (
  person_id TEXT PRIMARY KEY NOT NULL,
  archived INTEGER NOT NULL DEFAULT 0,
  photo_path TEXT
);
''');
    await customStatement('''
CREATE TABLE IF NOT EXISTS category_intel (
  category_id TEXT PRIMARY KEY NOT NULL,
  accent_color INTEGER NOT NULL DEFAULT 4285464311
);
''');
    await customStatement(
      'CREATE INDEX IF NOT EXISTS visit_logs_place ON visit_logs(place_id, ended_at);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS prompt_events_user ON prompt_events(user_id, created_at);',
    );
  }
}
