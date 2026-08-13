import '../core/constants/app_constants.dart';
import '../core/utils/ids.dart';
import '../domain/entities/entities.dart';
import '../domain/enums/enums.dart';

class OpportunityDecision {
  const OpportunityDecision({
    required this.score,
    required this.create,
    required this.reason,
  });

  final int score;
  final bool create;
  final String reason;
}

class PromptContext {
  const PromptContext({
    required this.settings,
    required this.weights,
    required this.thresholds,
    this.promptsToday = 0,
    this.recentPromptAtPlace = false,
    this.dismissedRecently = false,
    this.saidNothingRecently = false,
    this.alreadyRecorded = false,
    this.previouslySpent = false,
  });

  final AppSettings settings;
  final ScoringWeights weights;
  final ConfidenceThresholds thresholds;
  final int promptsToday;
  final bool recentPromptAtPlace;
  final bool dismissedRecently;
  final bool saidNothingRecently;
  final bool alreadyRecorded;
  final bool previouslySpent;
}

class OpportunityEngine {
  OpportunityDecision evaluate(VisitEvent visit, PromptContext ctx) {
    if (ctx.settings.promptStyle == PromptStyle.manualOnly) {
      return const OpportunityDecision(
        score: 0,
        create: false,
        reason: 'manual-only',
      );
    }
    if (ctx.alreadyRecorded) {
      return const OpportunityDecision(
        score: 0,
        create: false,
        reason: 'already-recorded',
      );
    }
    if (visit.passThrough) {
      return OpportunityDecision(
        score: (ctx.weights.passThrough).clamp(0, 100),
        create: false,
        reason: 'pass-through',
      );
    }

    var score = 0;
    final w = ctx.weights;
    score += w.newMeaningfulLocation;
    if (visit.place.type.isCommercial) score += w.commercialPlace;
    if (visit.duration.inMinutes >= 3) score += w.stayedOver3Min;
    if (visit.duration.inMinutes >= 10) score += w.stayedOver10Min;
    if (ctx.previouslySpent) {
      score += w.knownSpendingLocation;
      score += w.previouslySpentThere;
    }
    if (visit.returnedHome) score += w.returnedHomeAfterward;
    final minutes = visit.duration.inMinutes;
    if (minutes >= 2 && minutes <= 15 && visit.cameFromHome && visit.returnedHome) {
      score += w.veryShortTrip;
    }
    if (visit.place.type == PlaceType.home) score += w.knownHome;
    if (visit.place.type == PlaceType.work) score += w.knownOffice;
    if (ctx.recentPromptAtPlace) score += w.recentPromptSameLocation;
    if (ctx.dismissedRecently) score += w.userDismissedSameLocation;
    if (ctx.saidNothingRecently) score += w.userSaidNothingRecently;
    if (visit.locationConfidence < 0.4) score += w.veryLowLocationConfidence;

    if (visit.place.type == PlaceType.home) {
      return OpportunityDecision(score: score.clamp(0, 100), create: false, reason: 'home');
    }
    if (visit.place.type == PlaceType.work && visit.duration.inHours >= 4) {
      return OpportunityDecision(
        score: score.clamp(0, 100),
        create: false,
        reason: 'office-long-stay',
      );
    }

    final style = ctx.settings.promptStyle;
    var needed = ctx.thresholds.lowBelow;
    if (style == PromptStyle.frequent) needed = ctx.thresholds.ignoreBelow;
    if (style == PromptStyle.minimal) needed = ctx.thresholds.possibleBelow + 5;
    if (ctx.promptsToday >= ctx.settings.maxDailyPrompts) {
      return OpportunityDecision(
        score: score.clamp(0, 100),
        create: false,
        reason: 'daily-limit',
      );
    }
    if (!ctx.settings.askAfterLeaving && !visit.returnedHome) {
      return OpportunityDecision(
        score: score.clamp(0, 100),
        create: false,
        reason: 'ask-after-leaving-off',
      );
    }
    if (visit.returnedHome && !ctx.settings.askAfterReturningHome) {
      return OpportunityDecision(
        score: score.clamp(0, 100),
        create: false,
        reason: 'ask-after-home-off',
      );
    }

    final clamped = score.clamp(0, 100);
    final create = clamped >= needed;
    return OpportunityDecision(
      score: clamped,
      create: create,
      reason: create ? 'threshold-met' : 'below-threshold',
    );
  }

  ExpenseOpportunity toOpportunity({
    required VisitEvent visit,
    required String userId,
    required String deviceId,
    required int score,
    String? categoryId,
  }) {
    final now = DateTime.now().toUtc();
    return ExpenseOpportunity(
      id: newId(),
      userId: userId,
      placeId: visit.place.id,
      detectedAt: now,
      visitStartedAt: visit.startedAt,
      visitEndedAt: visit.endedAt,
      durationSeconds: visit.duration.inSeconds,
      confidenceScore: score,
      suggestedCategoryId: categoryId,
      suggestedMerchantName: visit.place.name,
      createdAt: now,
      updatedAt: now,
      deviceId: deviceId,
    );
  }
}
