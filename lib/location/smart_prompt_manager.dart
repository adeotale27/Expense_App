import '../domain/entities/entities.dart';
import '../domain/enums/enums.dart';
import '../domain/repositories/repositories.dart';

class PromptDecision {
  const PromptDecision({
    required this.allow,
    required this.reason,
  });

  final bool allow;
  final String reason;
}

/// Unified throttle for every contextual question.
class SmartPromptManager {
  SmartPromptManager(this.intel);

  final IntelRepository intel;

  static const homeCooldown = Duration(days: 21);
  static const workCooldown = Duration(days: 21);
  static const typeCooldown = Duration(days: 14);
  static const expensePlaceCooldown = Duration(hours: 18);

  bool inQuietHours(AppSettings settings, DateTime local) {
    final start = settings.quietHoursStart;
    final end = settings.quietHoursEnd;
    final h = local.hour;
    if (start == end) return false;
    if (start > end) return h >= start || h < end;
    return h >= start && h < end;
  }

  Future<PromptDecision> allow({
    required AppSettings settings,
    required PromptKind kind,
    String? placeId,
    DateTime? now,
    int extraPromptsToday = 0,
    bool dismissedRecently = false,
    bool saidNothingRecently = false,
  }) async {
    final ts = now ?? DateTime.now().toUtc();
    if (!settings.expensePrompts && kind == PromptKind.expenseOpportunity) {
      return const PromptDecision(allow: false, reason: 'expense-prompts-off');
    }
    if (!settings.homeDetection && kind == PromptKind.homeSuggestion) {
      return const PromptDecision(allow: false, reason: 'home-detection-off');
    }
    if (!settings.workDetection && kind == PromptKind.workSuggestion) {
      return const PromptDecision(allow: false, reason: 'work-detection-off');
    }
    if (!settings.smartPlaceDetection &&
        kind == PromptKind.placeTypeSuggestion) {
      return const PromptDecision(allow: false, reason: 'place-detection-off');
    }
    if (inQuietHours(settings, ts.toLocal())) {
      return const PromptDecision(allow: false, reason: 'quiet-hours');
    }
    final today = await intel.promptsToday(ts) + extraPromptsToday;
    if (today >= settings.maxDailyPrompts) {
      return const PromptDecision(allow: false, reason: 'daily-limit');
    }
    final last = await intel.lastPrompt(kind: kind, placeId: placeId);
    if (last != null) {
      final wait = switch (kind) {
        PromptKind.homeSuggestion => homeCooldown,
        PromptKind.workSuggestion => workCooldown,
        PromptKind.placeTypeSuggestion => typeCooldown,
        PromptKind.expenseOpportunity => Duration(hours: settings.placeCooldownHours),
      };
      if (ts.difference(last.createdAt) < wait) {
        return const PromptDecision(allow: false, reason: 'cooldown');
      }
      if (last.response == 'no' || last.response == 'dismissed') {
        final extra = wait * 2;
        if (ts.difference(last.createdAt) < extra) {
          return const PromptDecision(allow: false, reason: 'declined-cooldown');
        }
      }
    }
    if (dismissedRecently || saidNothingRecently) {
      return const PromptDecision(allow: false, reason: 'recent-negative');
    }
    return const PromptDecision(allow: true, reason: 'ok');
  }
}
