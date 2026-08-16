import 'package:equatable/equatable.dart';

import '../../core/utils/money.dart';
import '../enums/enums.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.displayName,
    this.email,
    this.provider = AuthProviderType.local,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String? email;
  final AuthProviderType provider;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, displayName, email, provider, createdAt];
}

class Category extends Equatable {
  const Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    this.accentColor = 0xFF6D5EF7,
    required this.isDefault,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.pending,
    required this.deviceId,
    this.version = 1,
  });

  final String id;
  final String userId;
  final String name;
  final String icon;
  final int accentColor;
  final bool isDefault;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;
  final String deviceId;
  final int version;

  Category copyWith({
    String? name,
    String? icon,
    int? accentColor,
    bool? isActive,
    int? sortOrder,
    DateTime? updatedAt,
    DateTime? deletedAt,
    SyncStatus? syncStatus,
    int? version,
  }) {
    return Category(
      id: id,
      userId: userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      accentColor: accentColor ?? this.accentColor,
      isDefault: isDefault,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      deviceId: deviceId,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [id, name, isActive, sortOrder, deletedAt];
}

class Expense extends Equatable {
  const Expense({
    required this.id,
    required this.userId,
    required this.amount,
    required this.categoryId,
    this.merchantName,
    this.placeId,
    this.paymentMethod = PaymentMethod.notSpecified,
    this.note,
    required this.timestamp,
    this.source = ExpenseSource.manual,
    this.opportunityId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.pending,
    required this.deviceId,
    this.version = 1,
  });

  final String id;
  final String userId;
  final Money amount;
  final String categoryId;
  final String? merchantName;
  final String? placeId;
  final PaymentMethod paymentMethod;
  final String? note;
  final DateTime timestamp;
  final ExpenseSource source;
  final String? opportunityId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;
  final String deviceId;
  final int version;

  bool get isDeleted => deletedAt != null;

  Expense copyWith({
    Money? amount,
    String? categoryId,
    String? merchantName,
    String? placeId,
    PaymentMethod? paymentMethod,
    String? note,
    DateTime? timestamp,
    DateTime? updatedAt,
    DateTime? deletedAt,
    SyncStatus? syncStatus,
    int? version,
    String? opportunityId,
  }) {
    return Expense(
      id: id,
      userId: userId,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      merchantName: merchantName ?? this.merchantName,
      placeId: placeId ?? this.placeId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      timestamp: timestamp ?? this.timestamp,
      source: source,
      opportunityId: opportunityId ?? this.opportunityId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      deviceId: deviceId,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [id, amount.minorUnits, categoryId, timestamp];
}

class Place extends Equatable {
  const Place({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.radius = 150,
    this.visitCount = 0,
    this.totalSpendMinor = 0,
    this.lastVisitedAt,
    this.firstVisitedAt,
    this.confidence = 0,
    this.userConfirmedName = false,
    this.geofenceEnabled = false,
    this.forgotten = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.pending,
    required this.deviceId,
    this.version = 1,
  });

  final String id;
  final String userId;
  final String name;
  final PlaceType type;
  final double latitude;
  final double longitude;
  final double radius;
  final int visitCount;
  final int totalSpendMinor;
  final DateTime? lastVisitedAt;
  final DateTime? firstVisitedAt;
  final int confidence;
  final bool userConfirmedName;
  final bool geofenceEnabled;
  final bool forgotten;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;
  final String deviceId;
  final int version;

  int get averageSpendMinor =>
      visitCount == 0 ? 0 : (totalSpendMinor / visitCount).round();

  Place copyWith({
    String? name,
    PlaceType? type,
    double? radius,
    int? visitCount,
    int? totalSpendMinor,
    DateTime? lastVisitedAt,
    DateTime? firstVisitedAt,
    int? confidence,
    bool? userConfirmedName,
    bool? geofenceEnabled,
    bool? forgotten,
    DateTime? updatedAt,
    DateTime? deletedAt,
    SyncStatus? syncStatus,
    int? version,
  }) {
    return Place(
      id: id,
      userId: userId,
      name: name ?? this.name,
      type: type ?? this.type,
      latitude: latitude,
      longitude: longitude,
      radius: radius ?? this.radius,
      visitCount: visitCount ?? this.visitCount,
      totalSpendMinor: totalSpendMinor ?? this.totalSpendMinor,
      lastVisitedAt: lastVisitedAt ?? this.lastVisitedAt,
      firstVisitedAt: firstVisitedAt ?? this.firstVisitedAt,
      confidence: confidence ?? this.confidence,
      userConfirmedName: userConfirmedName ?? this.userConfirmedName,
      geofenceEnabled: geofenceEnabled ?? this.geofenceEnabled,
      forgotten: forgotten ?? this.forgotten,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      deviceId: deviceId,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [id, name, type, latitude, longitude];
}

class Person extends Equatable {
  const Person({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.note,
    this.photoPath,
    this.archived = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.pending,
    required this.deviceId,
    this.version = 1,
  });

  final String id;
  final String userId;
  final String name;
  final String? phone;
  final String? note;
  final String? photoPath;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;
  final String deviceId;
  final int version;

  Person copyWith({
    String? name,
    String? phone,
    String? note,
    String? photoPath,
    bool? archived,
    DateTime? updatedAt,
    DateTime? deletedAt,
    SyncStatus? syncStatus,
    int? version,
  }) {
    return Person(
      id: id,
      userId: userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      note: note ?? this.note,
      photoPath: photoPath ?? this.photoPath,
      archived: archived ?? this.archived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      deviceId: deviceId,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [id, name, archived];
}

class LedgerEntry extends Equatable {
  const LedgerEntry({
    required this.id,
    required this.userId,
    required this.personId,
    required this.amount,
    required this.direction,
    required this.type,
    required this.date,
    this.note,
    this.relatedExpenseId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.pending,
    required this.deviceId,
    this.version = 1,
  });

  final String id;
  final String userId;
  final String personId;
  final Money amount;
  final LedgerDirection direction;
  final LedgerType type;
  final DateTime date;
  final String? note;
  final String? relatedExpenseId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;
  final String deviceId;
  final int version;

  /// Positive means the person owes the user. Negative means the user owes them.
  int get signedMinor {
    final mag = amount.minorUnits;
    return switch (type) {
      LedgerType.lent => mag,
      LedgerType.borrowed => -mag,
      LedgerType.repayment =>
        direction == LedgerDirection.owedToUser ? -mag : mag,
      LedgerType.settlement =>
        direction == LedgerDirection.owedToUser ? -mag : mag,
      LedgerType.adjustment =>
        direction == LedgerDirection.owedToUser ? mag : -mag,
    };
  }

  @override
  List<Object?> get props => [id, personId, amount.minorUnits, type];
}

class ExpenseOpportunity extends Equatable {
  const ExpenseOpportunity({
    required this.id,
    required this.userId,
    this.placeId,
    required this.detectedAt,
    required this.visitStartedAt,
    this.visitEndedAt,
    required this.durationSeconds,
    this.distanceFromPreviousPlace,
    required this.confidenceScore,
    this.suggestedCategoryId,
    this.suggestedMerchantName,
    this.status = OpportunityStatus.pending,
    this.notificationId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.pending,
    required this.deviceId,
    this.version = 1,
  });

  final String id;
  final String userId;
  final String? placeId;
  final DateTime detectedAt;
  final DateTime visitStartedAt;
  final DateTime? visitEndedAt;
  final int durationSeconds;
  final double? distanceFromPreviousPlace;
  final int confidenceScore;
  final String? suggestedCategoryId;
  final String? suggestedMerchantName;
  final OpportunityStatus status;
  final String? notificationId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;
  final String deviceId;
  final int version;

  ExpenseOpportunity copyWith({
    OpportunityStatus? status,
    String? notificationId,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    int? version,
  }) {
    return ExpenseOpportunity(
      id: id,
      userId: userId,
      placeId: placeId,
      detectedAt: detectedAt,
      visitStartedAt: visitStartedAt,
      visitEndedAt: visitEndedAt,
      durationSeconds: durationSeconds,
      distanceFromPreviousPlace: distanceFromPreviousPlace,
      confidenceScore: confidenceScore,
      suggestedCategoryId: suggestedCategoryId,
      suggestedMerchantName: suggestedMerchantName,
      status: status ?? this.status,
      notificationId: notificationId ?? this.notificationId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      deviceId: deviceId,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [id, status, confidenceScore, placeId];
}

class RecurringExpense extends Equatable {
  const RecurringExpense({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.frequency,
    required this.categoryId,
    required this.nextExpectedDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.pending,
    required this.deviceId,
    this.version = 1,
  });

  final String id;
  final String userId;
  final String name;
  final Money amount;
  final String frequency;
  final String categoryId;
  final DateTime nextExpectedDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;
  final String deviceId;
  final int version;

  @override
  List<Object?> get props => [id, name, amount.minorUnits, frequency];
}

class AppSettings extends Equatable {
  const AppSettings({
    required this.userId,
    this.currencyCode = 'INR',
    this.promptStyle = PromptStyle.smart,
    this.minStopMinutes = 3,
    this.askAfterLeaving = true,
    this.askAfterReturningHome = true,
    this.eveningReview = true,
    this.maxDailyPrompts = 3,
    this.themeMode = 'system',
    this.onboardingComplete = false,
    this.homePlaceId,
    this.workPlaceId,
    this.backgroundLocation = true,
    this.smartPlaceDetection = true,
    this.homeDetection = true,
    this.workDetection = true,
    this.expensePrompts = true,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 7,
    this.placeCooldownHours = 18,
    this.lastCategoryId,
    this.lastPaymentMethod = PaymentMethod.upi,
    this.scoring = const ScoringConfig(),
  });

  final String userId;
  final String currencyCode;
  final PromptStyle promptStyle;
  final int minStopMinutes;
  final bool askAfterLeaving;
  final bool askAfterReturningHome;
  final bool eveningReview;
  final int maxDailyPrompts;
  final String themeMode;
  final bool onboardingComplete;
  final String? homePlaceId;
  final String? workPlaceId;
  final bool backgroundLocation;
  final bool smartPlaceDetection;
  final bool homeDetection;
  final bool workDetection;
  final bool expensePrompts;
  final int quietHoursStart;
  final int quietHoursEnd;
  final int placeCooldownHours;
  final String? lastCategoryId;
  final PaymentMethod lastPaymentMethod;
  final ScoringConfig scoring;

  AppSettings copyWith({
    String? currencyCode,
    PromptStyle? promptStyle,
    int? minStopMinutes,
    bool? askAfterLeaving,
    bool? askAfterReturningHome,
    bool? eveningReview,
    int? maxDailyPrompts,
    String? themeMode,
    bool? onboardingComplete,
    String? homePlaceId,
    String? workPlaceId,
    bool? backgroundLocation,
    bool? smartPlaceDetection,
    bool? homeDetection,
    bool? workDetection,
    bool? expensePrompts,
    int? quietHoursStart,
    int? quietHoursEnd,
    int? placeCooldownHours,
    String? lastCategoryId,
    PaymentMethod? lastPaymentMethod,
    ScoringConfig? scoring,
  }) {
    return AppSettings(
      userId: userId,
      currencyCode: currencyCode ?? this.currencyCode,
      promptStyle: promptStyle ?? this.promptStyle,
      minStopMinutes: minStopMinutes ?? this.minStopMinutes,
      askAfterLeaving: askAfterLeaving ?? this.askAfterLeaving,
      askAfterReturningHome:
          askAfterReturningHome ?? this.askAfterReturningHome,
      eveningReview: eveningReview ?? this.eveningReview,
      maxDailyPrompts: maxDailyPrompts ?? this.maxDailyPrompts,
      themeMode: themeMode ?? this.themeMode,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      homePlaceId: homePlaceId ?? this.homePlaceId,
      workPlaceId: workPlaceId ?? this.workPlaceId,
      backgroundLocation: backgroundLocation ?? this.backgroundLocation,
      smartPlaceDetection: smartPlaceDetection ?? this.smartPlaceDetection,
      homeDetection: homeDetection ?? this.homeDetection,
      workDetection: workDetection ?? this.workDetection,
      expensePrompts: expensePrompts ?? this.expensePrompts,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      placeCooldownHours: placeCooldownHours ?? this.placeCooldownHours,
      lastCategoryId: lastCategoryId ?? this.lastCategoryId,
      lastPaymentMethod: lastPaymentMethod ?? this.lastPaymentMethod,
      scoring: scoring ?? this.scoring,
    );
  }

  @override
  List<Object?> get props =>
      [userId, promptStyle, minStopMinutes, maxDailyPrompts, themeMode];
}

class ScoringConfig extends Equatable {
  const ScoringConfig({
    this.weights = const {},
    this.ignoreBelow = 40,
    this.lowBelow = 60,
    this.possibleBelow = 75,
  });

  final Map<String, int> weights;
  final int ignoreBelow;
  final int lowBelow;
  final int possibleBelow;

  @override
  List<Object?> get props => [weights, ignoreBelow, lowBelow, possibleBelow];
}

class VisitLog {
  const VisitLog({
    required this.id,
    required this.userId,
    required this.placeId,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.hourOfDay,
    required this.weekday,
    this.passThrough = false,
  });

  final String id;
  final String userId;
  final String placeId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSeconds;
  final int hourOfDay;
  final int weekday;
  final bool passThrough;
}

class PromptEvent {
  const PromptEvent({
    required this.id,
    required this.userId,
    required this.kind,
    this.placeId,
    required this.createdAt,
    this.response,
  });

  final String id;
  final String userId;
  final PromptKind kind;
  final String? placeId;
  final DateTime createdAt;
  final String? response;
}

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.place,
    required this.kind,
    required this.confidence,
    required this.headline,
    required this.body,
  });

  final Place place;
  final PromptKind kind;
  final int confidence;
  final String headline;
  final String body;
}

class SpendingHabits {
  const SpendingHabits({
    this.frequentCategoryId,
    this.recentCategoryId,
    this.frequentPayment = PaymentMethod.upi,
    this.recentPayment = PaymentMethod.upi,
    this.frequentPlaceIds = const [],
    this.groceryLike = false,
    this.hangoutPlaceIds = const [],
    this.typicalQuickAmounts = const [10000, 20000, 50000],
  });

  final String? frequentCategoryId;
  final String? recentCategoryId;
  final PaymentMethod frequentPayment;
  final PaymentMethod recentPayment;
  final List<String> frequentPlaceIds;
  final bool groceryLike;
  final List<String> hangoutPlaceIds;
  final List<int> typicalQuickAmounts;
}

class GeofenceEvent {
  const GeofenceEvent({
    required this.place,
    required this.entered,
    required this.at,
  });

  final Place place;
  final bool entered;
  final DateTime at;
}

class VisitEvent {
  const VisitEvent({
    required this.place,
    required this.startedAt,
    required this.endedAt,
    required this.duration,
    required this.passThrough,
    this.returnedHome = false,
    this.cameFromHome = false,
    this.locationConfidence = 1,
  });

  final Place place;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration duration;
  final bool passThrough;
  final bool returnedHome;
  final bool cameFromHome;
  final double locationConfidence;
}
