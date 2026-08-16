import 'package:drift/drift.dart';

import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/enums.dart';
import '../../domain/repositories/repositories.dart';
import '../local/app_database.dart';

class DriftIntelRepository implements IntelRepository {
  DriftIntelRepository(this.db, this.userId);
  final AppDatabase db;
  final String userId;

  @override
  Future<void> recordVisit(VisitLog log) async {
    await db.customStatement(
      '''
INSERT OR REPLACE INTO visit_logs
(id, user_id, place_id, started_at, ended_at, duration_seconds, hour_of_day, weekday, pass_through)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
      [
        log.id,
        log.userId,
        log.placeId,
        log.startedAt.millisecondsSinceEpoch,
        log.endedAt.millisecondsSinceEpoch,
        log.durationSeconds,
        log.hourOfDay,
        log.weekday,
        log.passThrough ? 1 : 0,
      ],
    );
  }

  @override
  Future<List<VisitLog>> visitsFor(String placeId) async {
    final rows = await db.customSelect(
      'SELECT * FROM visit_logs WHERE user_id = ? AND place_id = ? ORDER BY ended_at DESC',
      variables: [
        Variable.withString(userId),
        Variable.withString(placeId),
      ],
      readsFrom: {},
    ).get();
    return rows.map(_visit).toList();
  }

  @override
  Future<List<VisitLog>> recentVisits({int limit = 200}) async {
    final rows = await db.customSelect(
      'SELECT * FROM visit_logs WHERE user_id = ? ORDER BY ended_at DESC LIMIT ?',
      variables: [
        Variable.withString(userId),
        Variable.withInt(limit),
      ],
      readsFrom: {},
    ).get();
    return rows.map(_visit).toList();
  }

  @override
  Future<void> recordPrompt(PromptEvent event) async {
    await db.customStatement(
      '''
INSERT OR REPLACE INTO prompt_events
(id, user_id, kind, place_id, created_at, response)
VALUES (?, ?, ?, ?, ?, ?)
''',
      [
        event.id,
        event.userId,
        event.kind.name,
        event.placeId,
        event.createdAt.millisecondsSinceEpoch,
        event.response,
      ],
    );
  }

  @override
  Future<List<PromptEvent>> recentPrompts({int limit = 200}) async {
    final rows = await db.customSelect(
      'SELECT * FROM prompt_events WHERE user_id = ? ORDER BY created_at DESC LIMIT ?',
      variables: [
        Variable.withString(userId),
        Variable.withInt(limit),
      ],
      readsFrom: {},
    ).get();
    return rows.map(_prompt).toList();
  }

  @override
  Future<int> promptsToday(DateTime nowUtc) async {
    final start = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
    final rows = await db.customSelect(
      'SELECT COUNT(*) AS c FROM prompt_events WHERE user_id = ? AND created_at >= ?',
      variables: [
        Variable.withString(userId),
        Variable.withInt(start.millisecondsSinceEpoch),
      ],
      readsFrom: {},
    ).get();
    return rows.first.read<int>('c');
  }

  @override
  Future<PromptEvent?> lastPrompt({
    required PromptKind kind,
    String? placeId,
  }) async {
    final sql = placeId == null
        ? 'SELECT * FROM prompt_events WHERE user_id = ? AND kind = ? ORDER BY created_at DESC LIMIT 1'
        : 'SELECT * FROM prompt_events WHERE user_id = ? AND kind = ? AND place_id = ? ORDER BY created_at DESC LIMIT 1';
    final vars = placeId == null
        ? [Variable.withString(userId), Variable.withString(kind.name)]
        : [
            Variable.withString(userId),
            Variable.withString(kind.name),
            Variable.withString(placeId),
          ];
    final rows = await db.customSelect(sql, variables: vars, readsFrom: {}).get();
    if (rows.isEmpty) return null;
    return _prompt(rows.first);
  }

  Future<void> savePlaceIntel(Place place) async {
    await db.customStatement(
      '''
INSERT OR REPLACE INTO place_intel
(place_id, first_visited_at, confidence, user_confirmed, geofence_enabled, forgotten)
VALUES (?, ?, ?, ?, ?, ?)
''',
      [
        place.id,
        place.firstVisitedAt?.millisecondsSinceEpoch,
        place.confidence,
        place.userConfirmedName ? 1 : 0,
        place.geofenceEnabled ? 1 : 0,
        place.forgotten ? 1 : 0,
      ],
    );
  }

  Future<Map<String, PlaceExtras>> loadPlaceIntel() async {
    final rows = await db
        .customSelect('SELECT * FROM place_intel', readsFrom: {})
        .get();
    return {
      for (final r in rows)
        r.read<String>('place_id'): PlaceExtras(
          firstVisitedAt: r.readNullable<int>('first_visited_at') == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(
                  r.read<int>('first_visited_at'),
                  isUtc: true,
                ),
          confidence: r.read<int>('confidence'),
          userConfirmed: r.read<int>('user_confirmed') == 1,
          geofence: r.read<int>('geofence_enabled') == 1,
          forgotten: r.read<int>('forgotten') == 1,
        ),
    };
  }

  Future<void> savePersonIntel(Person person) async {
    await db.customStatement(
      '''
INSERT OR REPLACE INTO people_intel (person_id, archived, photo_path)
VALUES (?, ?, ?)
''',
      [person.id, person.archived ? 1 : 0, person.photoPath],
    );
  }

  Future<Map<String, (bool, String?)>> loadPeopleIntel() async {
    final rows = await db
        .customSelect('SELECT * FROM people_intel', readsFrom: {})
        .get();
    return {
      for (final r in rows)
        r.read<String>('person_id'): (
          r.read<int>('archived') == 1,
          r.readNullable<String>('photo_path'),
        ),
    };
  }

  Future<void> saveCategoryColor(String id, int color) async {
    await db.customStatement(
      'INSERT OR REPLACE INTO category_intel (category_id, accent_color) VALUES (?, ?)',
      [id, color],
    );
  }

  Future<Map<String, int>> loadCategoryColors() async {
    final rows = await db
        .customSelect('SELECT * FROM category_intel', readsFrom: {})
        .get();
    return {
      for (final r in rows)
        r.read<String>('category_id'): r.read<int>('accent_color'),
    };
  }

  VisitLog _visit(QueryRow r) => VisitLog(
        id: r.read<String>('id'),
        userId: r.read<String>('user_id'),
        placeId: r.read<String>('place_id'),
        startedAt: DateTime.fromMillisecondsSinceEpoch(
          r.read<int>('started_at'),
          isUtc: true,
        ),
        endedAt: DateTime.fromMillisecondsSinceEpoch(
          r.read<int>('ended_at'),
          isUtc: true,
        ),
        durationSeconds: r.read<int>('duration_seconds'),
        hourOfDay: r.read<int>('hour_of_day'),
        weekday: r.read<int>('weekday'),
        passThrough: r.read<int>('pass_through') == 1,
      );

  PromptEvent _prompt(QueryRow r) => PromptEvent(
        id: r.read<String>('id'),
        userId: r.read<String>('user_id'),
        kind: PromptKind.values.byName(r.read<String>('kind')),
        placeId: r.readNullable<String>('place_id'),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          r.read<int>('created_at'),
          isUtc: true,
        ),
        response: r.readNullable<String>('response'),
      );
}

class PlaceExtras {
  const PlaceExtras({
    required this.firstVisitedAt,
    required this.confidence,
    required this.userConfirmed,
    required this.geofence,
    required this.forgotten,
  });
  final DateTime? firstVisitedAt;
  final int confidence;
  final bool userConfirmed;
  final bool geofence;
  final bool forgotten;
}

Place mergePlaceIntel(Place place, Map<String, PlaceExtras> extras) {
  final x = extras[place.id];
  if (x == null) return place;
  return place.copyWith(
    firstVisitedAt: x.firstVisitedAt,
    confidence: x.confidence,
    userConfirmedName: x.userConfirmed,
    geofenceEnabled: x.geofence,
    forgotten: x.forgotten,
  );
}

String newVisitId() => newId();
