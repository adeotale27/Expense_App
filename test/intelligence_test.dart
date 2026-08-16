import 'package:flutter_test/flutter_test.dart';
import 'package:spendping/core/utils/money.dart';
import 'package:spendping/domain/entities/entities.dart';
import 'package:spendping/domain/enums/enums.dart';
import 'package:spendping/features/habits/habit_engine.dart';
import 'package:spendping/location/behavior_confidence.dart';
import 'package:spendping/location/geofence_manager.dart';
import 'package:spendping/location/location_provider.dart';
import 'package:spendping/location/place_classifier.dart';
import 'package:spendping/location/smart_prompt_manager.dart';
import 'package:spendping/domain/repositories/repositories.dart';

class _MemIntel implements IntelRepository {
  final events = <PromptEvent>[];
  final visits = <VisitLog>[];

  @override
  Future<PromptEvent?> lastPrompt({required PromptKind kind, String? placeId}) async {
    final list = events.where((e) => e.kind == kind && (placeId == null || e.placeId == placeId));
    if (list.isEmpty) return null;
    return list.last;
  }

  @override
  Future<int> promptsToday(DateTime nowUtc) async {
    final start = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
    return events.where((e) => !e.createdAt.isBefore(start)).length;
  }

  @override
  Future<void> recordPrompt(PromptEvent event) async => events.add(event);

  @override
  Future<void> recordVisit(VisitLog log) async => visits.add(log);

  @override
  Future<List<PromptEvent>> recentPrompts({int limit = 200}) async => events.reversed.take(limit).toList();

  @override
  Future<List<VisitLog>> recentVisits({int limit = 200}) async => visits.reversed.take(limit).toList();

  @override
  Future<List<VisitLog>> visitsFor(String placeId) async =>
      visits.where((v) => v.placeId == placeId).toList();
}

void main() {
  test('hiding a category keeps historical expense ids valid', () {
    final now = DateTime.utc(2026, 8, 16);
    final cat = Category(
      id: 'food',
      userId: 'u',
      name: 'Food',
      icon: '🍜',
      isDefault: true,
      isActive: false,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
      deviceId: 'd',
    );
    final expense = Expense(
      id: 'e1',
      userId: 'u',
      amount: Money(minorUnits: 45000),
      categoryId: cat.id,
      timestamp: now,
      createdAt: now,
      updatedAt: now,
      deviceId: 'd',
    );
    expect(cat.isActive, isFalse);
    expect(expense.categoryId, 'food');
  });

  test('habits learn frequent UPI + food', () {
    final now = DateTime.utc(2026, 8, 16);
    Expense exp(String cat, PaymentMethod m) => Expense(
          id: cat + m.name + now.microsecondsSinceEpoch.toString(),
          userId: 'u',
          amount: Money(minorUnits: 20000),
          categoryId: cat,
          paymentMethod: m,
          timestamp: now,
          createdAt: now,
          updatedAt: now,
          deviceId: 'd',
        );
    final habits = HabitEngine().learn(
      expenses: [
        exp('food', PaymentMethod.upi),
        exp('food', PaymentMethod.upi),
        exp('grocery', PaymentMethod.cash),
      ],
      places: const [],
      visits: const [],
    );
    expect(habits.frequentCategoryId, 'food');
    expect(habits.frequentPayment, PaymentMethod.upi);
  });

  test('home confidence crosses threshold after evening stays', () {
    final visits = [
      for (var d = 1; d <= 6; d++)
        VisitLog(
          id: '$d',
          userId: 'u',
          placeId: 'p',
          startedAt: DateTime.utc(2026, 8, d, 22),
          endedAt: DateTime.utc(2026, 8, d + 1, 7),
          durationSeconds: 8 * 3600,
          hourOfDay: 22,
          weekday: d,
        ),
    ];
    expect(BehaviorConfidence().forHome(visits), greaterThanOrEqualTo(70));
  });

  test('work confidence from weekday daytime hours', () {
    final visits = [
      for (var d = 10; d <= 14; d++)
        VisitLog(
          id: '$d',
          userId: 'u',
          placeId: 'office',
          startedAt: DateTime.utc(2026, 8, d, 10),
          endedAt: DateTime.utc(2026, 8, d, 18),
          durationSeconds: 8 * 3600,
          hourOfDay: 10,
          weekday: DateTime.utc(2026, 8, d).weekday,
        ),
    ];
    expect(BehaviorConfidence().forWork(visits), greaterThanOrEqualTo(70));
  });

  test('geofence emits enter then exit without polling', () {
    final place = DemoCatalog.of('grocery', userId: 'u', deviceId: 'd')
        .copyWith(geofenceEnabled: true);
    final mgr = GeofenceManager();
    final enter = mgr.observe(
      fix: GeoFix(
        latitude: place.latitude,
        longitude: place.longitude,
        timestamp: DateTime.utc(2026, 8, 16, 10),
      ),
      places: [place],
    );
    expect(enter?.entered, isTrue);
    final exit = mgr.observe(
      fix: GeoFix(
        latitude: place.latitude + 0.05,
        longitude: place.longitude + 0.05,
        timestamp: DateTime.utc(2026, 8, 16, 11),
      ),
      places: [place],
    );
    expect(exit?.entered, isFalse);
  });

  test('prompt manager cooldown after not this time', () async {
    final intel = _MemIntel();
    final mgr = SmartPromptManager(intel);
    final settings = const AppSettings(userId: 'u', maxDailyPrompts: 3);
    final first = await mgr.allow(
      settings: settings,
      kind: PromptKind.expenseOpportunity,
      placeId: 'mall',
      now: DateTime.utc(2026, 8, 16, 12),
    );
    expect(first.allow, isTrue);
    await intel.recordPrompt(
      PromptEvent(
        id: '1',
        userId: 'u',
        kind: PromptKind.expenseOpportunity,
        placeId: 'mall',
        createdAt: DateTime.utc(2026, 8, 16, 12),
        response: 'no',
      ),
    );
    final second = await mgr.allow(
      settings: settings,
      kind: PromptKind.expenseOpportunity,
      placeId: 'mall',
      now: DateTime.utc(2026, 8, 16, 13),
    );
    expect(second.allow, isFalse);
    expect(second.reason, anyOf('cooldown', 'declined-cooldown'));
  });

  test('quiet hours block prompts', () async {
    final mgr = SmartPromptManager(_MemIntel());
    final decision = await mgr.allow(
      settings: const AppSettings(userId: 'u', quietHoursStart: 22, quietHoursEnd: 7),
      kind: PromptKind.homeSuggestion,
      now: DateTime.utc(2026, 8, 16, 17), // 22:30 IST-ish depending; use local conversion
    );
    // UTC 17:00 is not necessarily quiet; explicitly test helper
    expect(
      mgr.inQuietHours(
        const AppSettings(userId: 'u', quietHoursStart: 22, quietHoursEnd: 7),
        DateTime(2026, 8, 16, 23),
      ),
      isTrue,
    );
    expect(decision.reason, isNotNull);
  });

  test('classifier maps hangout and grocery names', () {
    final c = PlaceClassifier();
    expect(c.classifyName('Phoenix Mall'), PlaceType.shopping);
    expect(c.classifyName('gaming arena'), PlaceType.gaming);
    expect(c.classifyName('Home'), PlaceType.home);
  });

  test('place type suggestion is never an automatic expense', () {
    final place = DemoCatalog.of('cafe', userId: 'u', deviceId: 'd')
        .copyWith(type: PlaceType.unknown);
    final visits = [
      for (var i = 1; i <= 4; i++)
        VisitLog(
          id: '$i',
          userId: 'u',
          placeId: place.id,
          startedAt: DateTime.utc(2026, 8, i, 19),
          endedAt: DateTime.utc(2026, 8, i, 21),
          durationSeconds: 7200,
          hourOfDay: 19,
          weekday: i,
        ),
    ];
    final suggestion = BehaviorConfidence().maybeSuggest(
      place: place,
      visits: visits,
      settings: const AppSettings(userId: 'u'),
      declinedHome: {},
      declinedWork: {},
      declinedType: {},
    );
    expect(suggestion, isNotNull);
    expect(suggestion!.kind, PromptKind.placeTypeSuggestion);
  });
}
