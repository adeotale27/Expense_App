import 'package:flutter_test/flutter_test.dart';
import 'package:spendping/core/constants/app_constants.dart';
import 'package:spendping/domain/entities/entities.dart';
import 'package:spendping/domain/enums/enums.dart';
import 'package:spendping/location/movement_engine.dart';
import 'package:spendping/location/opportunity_engine.dart';
import 'package:spendping/location/place_classifier.dart';
import 'package:spendping/location/location_provider.dart';

void main() {
  final user = 'u';
  final device = 'd';
  late MovementEngine movement;
  late OpportunityEngine opp;

  setUp(() {
    movement = MovementEngine(
      homePlace: DemoCatalog.of('home', userId: user, deviceId: device),
    );
    opp = OpportunityEngine();
  });

  PromptContext ctx({int prompts = 0, bool recorded = false}) => PromptContext(
        settings: const AppSettings(userId: 'u'),
        weights: const ScoringWeights(),
        thresholds: const ConfidenceThresholds(),
        promptsToday: prompts,
        alreadyRecorded: recorded,
        previouslySpent: false,
      );

  List<Place> catalog() => DemoCatalog.all(userId: user, deviceId: device);

  VisitEvent? run(List<(String key, Duration offset)> steps) {
    VisitEvent? last;
    final t0 = DateTime(2026, 8, 13, 10);
    for (final step in steps) {
      final place = DemoCatalog.of(step.$1, userId: user, deviceId: device);
      final tick = movement.tick(
        fix: GeoFix(
          latitude: place.latitude,
          longitude: place.longitude,
          timestamp: t0.add(step.$2),
        ),
        knownPlaces: catalog(),
        minStopMinutes: 3,
      );
      last = tick.completedVisit ?? last;
    }
    return last;
  }

  test('home → grocery 7 min → home creates a visit', () {
    final visit = run([
      ('home', Duration.zero),
      ('grocery', const Duration(minutes: 1)),
      ('grocery', const Duration(minutes: 8)),
      ('home', const Duration(minutes: 10)),
    ]);
    expect(visit, isNotNull);
    expect(visit!.place.type, PlaceType.grocery);
    expect(visit.passThrough, isFalse);
    expect(visit.returnedHome, isTrue);
    final decision = opp.evaluate(visit, ctx());
    expect(decision.create, isTrue);
    expect(decision.score, greaterThanOrEqualTo(60));
  });

  test('short milk trip still eligible', () {
    final visit = run([
      ('home', Duration.zero),
      ('milk', const Duration(minutes: 1)),
      ('milk', const Duration(minutes: 5)),
      ('home', const Duration(minutes: 7)),
    ]);
    expect(visit, isNotNull);
    expect(visit!.passThrough, isFalse);
    expect(opp.evaluate(visit, ctx()).create, isTrue);
  });

  test('pass-through restaurant does not prompt', () {
    final visit = run([
      ('home', Duration.zero),
      ('restaurant', const Duration(seconds: 10)),
      ('restaurant', const Duration(seconds: 40)),
      ('home', const Duration(seconds: 50)),
    ]);
    expect(visit, isNotNull);
    expect(visit!.passThrough, isTrue);
    expect(opp.evaluate(visit, ctx()).create, isFalse);
  });

  test('office long stay does not repeatedly prompt', () {
    final visit = run([
      ('home', Duration.zero),
      ('office', const Duration(minutes: 5)),
      ('office', const Duration(hours: 8)),
      ('home', const Duration(hours: 8, minutes: 10)),
    ]);
    expect(visit, isNotNull);
    expect(opp.evaluate(visit!, ctx()).reason, 'office-long-stay');
    expect(opp.evaluate(visit, ctx()).create, isFalse);
  });

  test('duplicate already recorded is ignored', () {
    final visit = run([
      ('home', Duration.zero),
      ('grocery', const Duration(minutes: 1)),
      ('grocery', const Duration(minutes: 8)),
      ('home', const Duration(minutes: 10)),
    ]);
    expect(opp.evaluate(visit!, ctx(recorded: true)).create, isFalse);
  });

  test('cooldown via recent prompt does not create', () {
    final visit = run([
      ('home', Duration.zero),
      ('grocery', const Duration(minutes: 1)),
      ('grocery', const Duration(minutes: 8)),
      ('home', const Duration(minutes: 10)),
    ]);
    final decision = opp.evaluate(
      visit!,
      PromptContext(
        settings: const AppSettings(userId: 'u'),
        weights: const ScoringWeights(),
        thresholds: const ConfidenceThresholds(),
        recentPromptAtPlace: true,
      ),
    );
    expect(decision.create, isFalse);
  });

  test('user said nothing recently lowers score below threshold', () {
    final visit = run([
      ('home', Duration.zero),
      ('grocery', const Duration(minutes: 1)),
      ('grocery', const Duration(minutes: 8)),
      ('home', const Duration(minutes: 10)),
    ]);
    final decision = opp.evaluate(
      visit!,
      PromptContext(
        settings: const AppSettings(userId: 'u'),
        weights: const ScoringWeights(),
        thresholds: const ConfidenceThresholds(),
        saidNothingRecently: true,
      ),
    );
    expect(decision.create, isFalse);
  });
}
