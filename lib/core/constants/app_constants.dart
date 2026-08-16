class AppConstants {
  static const appName = 'SpendPing';
  static const defaultCurrency = 'INR';
  static const pageSize = 50;
  static const maxDailyPromptsDefault = 3;
  static const minStopMinutesDefault = 3;
  static const rawLocationRetentionHours = 24;
  static const opportunityExpiryHours = 36;
}

class ScoringWeights {
  const ScoringWeights({
    this.newMeaningfulLocation = 20,
    this.commercialPlace = 20,
    this.stayedOver3Min = 15,
    this.stayedOver10Min = 10,
    this.knownSpendingLocation = 20,
    this.previouslySpentThere = 15,
    this.returnedHomeAfterward = 10,
    this.veryShortTrip = 5,
    this.knownHome = -50,
    this.knownOffice = -20,
    this.recentPromptSameLocation = -50,
    this.userDismissedSameLocation = -40,
    this.userSaidNothingRecently = -40,
    this.passThrough = -30,
    this.veryLowLocationConfidence = -30,
  });

  final int newMeaningfulLocation;
  final int commercialPlace;
  final int stayedOver3Min;
  final int stayedOver10Min;
  final int knownSpendingLocation;
  final int previouslySpentThere;
  final int returnedHomeAfterward;
  final int veryShortTrip;
  final int knownHome;
  final int knownOffice;
  final int recentPromptSameLocation;
  final int userDismissedSameLocation;
  final int userSaidNothingRecently;
  final int passThrough;
  final int veryLowLocationConfidence;

  Map<String, int> toMap() => {
        'newMeaningfulLocation': newMeaningfulLocation,
        'commercialPlace': commercialPlace,
        'stayedOver3Min': stayedOver3Min,
        'stayedOver10Min': stayedOver10Min,
        'knownSpendingLocation': knownSpendingLocation,
        'previouslySpentThere': previouslySpentThere,
        'returnedHomeAfterward': returnedHomeAfterward,
        'veryShortTrip': veryShortTrip,
        'knownHome': knownHome,
        'knownOffice': knownOffice,
        'recentPromptSameLocation': recentPromptSameLocation,
        'userDismissedSameLocation': userDismissedSameLocation,
        'userSaidNothingRecently': userSaidNothingRecently,
        'passThrough': passThrough,
        'veryLowLocationConfidence': veryLowLocationConfidence,
      };

  factory ScoringWeights.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ScoringWeights();
    int v(String k, int d) => (map[k] as num?)?.toInt() ?? d;
    const d = ScoringWeights();
    return ScoringWeights(
      newMeaningfulLocation: v('newMeaningfulLocation', d.newMeaningfulLocation),
      commercialPlace: v('commercialPlace', d.commercialPlace),
      stayedOver3Min: v('stayedOver3Min', d.stayedOver3Min),
      stayedOver10Min: v('stayedOver10Min', d.stayedOver10Min),
      knownSpendingLocation: v('knownSpendingLocation', d.knownSpendingLocation),
      previouslySpentThere: v('previouslySpentThere', d.previouslySpentThere),
      returnedHomeAfterward: v('returnedHomeAfterward', d.returnedHomeAfterward),
      veryShortTrip: v('veryShortTrip', d.veryShortTrip),
      knownHome: v('knownHome', d.knownHome),
      knownOffice: v('knownOffice', d.knownOffice),
      recentPromptSameLocation:
          v('recentPromptSameLocation', d.recentPromptSameLocation),
      userDismissedSameLocation:
          v('userDismissedSameLocation', d.userDismissedSameLocation),
      userSaidNothingRecently:
          v('userSaidNothingRecently', d.userSaidNothingRecently),
      passThrough: v('passThrough', d.passThrough),
      veryLowLocationConfidence:
          v('veryLowLocationConfidence', d.veryLowLocationConfidence),
    );
  }
}

class ConfidenceThresholds {
  const ConfidenceThresholds({
    this.ignoreBelow = 40,
    this.lowBelow = 60,
    this.possibleBelow = 75,
  });

  final int ignoreBelow;
  final int lowBelow;
  final int possibleBelow;

  Map<String, int> toMap() => {
        'ignoreBelow': ignoreBelow,
        'lowBelow': lowBelow,
        'possibleBelow': possibleBelow,
      };

  factory ConfidenceThresholds.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ConfidenceThresholds();
    return ConfidenceThresholds(
      ignoreBelow: (map['ignoreBelow'] as num?)?.toInt() ?? 40,
      lowBelow: (map['lowBelow'] as num?)?.toInt() ?? 60,
      possibleBelow: (map['possibleBelow'] as num?)?.toInt() ?? 75,
    );
  }
}
