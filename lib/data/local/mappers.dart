import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/money.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/enums.dart';
import 'app_database.dart';

Expense expenseFromRow(ExpenseData row) => Expense(
      id: row.id,
      userId: row.userId,
      amount: Money(minorUnits: row.amountMinor, currencyCode: row.currencyCode),
      categoryId: row.categoryId,
      merchantName: row.merchantName,
      placeId: row.placeId,
      paymentMethod: _payment(row.paymentMethod),
      note: row.note,
      timestamp: row.timestamp,
      source: ExpenseSource.values.byName(row.source),
      opportunityId: row.opportunityId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      syncStatus: SyncStatus.values.byName(row.syncStatus),
      deviceId: row.deviceId,
      version: row.version,
    );

ExpensesCompanion expenseToRow(Expense e) => ExpensesCompanion(
      id: Value(e.id),
      userId: Value(e.userId),
      amountMinor: Value(e.amount.minorUnits),
      currencyCode: Value(e.amount.currencyCode),
      categoryId: Value(e.categoryId),
      merchantName: Value(e.merchantName),
      placeId: Value(e.placeId),
      paymentMethod: Value(e.paymentMethod.name),
      note: Value(e.note),
      timestamp: Value(e.timestamp),
      source: Value(e.source.name),
      opportunityId: Value(e.opportunityId),
      createdAt: Value(e.createdAt),
      updatedAt: Value(e.updatedAt),
      deletedAt: Value(e.deletedAt),
      syncStatus: Value(e.syncStatus.name),
      deviceId: Value(e.deviceId),
      version: Value(e.version),
    );

Category categoryFromRow(CategoryData row) => Category(
      id: row.id,
      userId: row.userId,
      name: row.name,
      icon: row.icon,
      isDefault: row.isDefault,
      isActive: row.isActive,
      sortOrder: row.sortOrder,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      syncStatus: SyncStatus.values.byName(row.syncStatus),
      deviceId: row.deviceId,
      version: row.version,
    );

CategoriesCompanion categoryToRow(Category c) => CategoriesCompanion(
      id: Value(c.id),
      userId: Value(c.userId),
      name: Value(c.name),
      icon: Value(c.icon),
      isDefault: Value(c.isDefault),
      isActive: Value(c.isActive),
      sortOrder: Value(c.sortOrder),
      createdAt: Value(c.createdAt),
      updatedAt: Value(c.updatedAt),
      deletedAt: Value(c.deletedAt),
      syncStatus: Value(c.syncStatus.name),
      deviceId: Value(c.deviceId),
      version: Value(c.version),
    );

Place placeFromRow(PlaceData row) => Place(
      id: row.id,
      userId: row.userId,
      name: row.name,
      type: PlaceType.values.byName(row.type),
      latitude: row.latitude,
      longitude: row.longitude,
      radius: row.radius,
      visitCount: row.visitCount,
      totalSpendMinor: row.totalSpendMinor,
      lastVisitedAt: row.lastVisitedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      syncStatus: SyncStatus.values.byName(row.syncStatus),
      deviceId: row.deviceId,
      version: row.version,
    );

PlacesCompanion placeToRow(Place p) => PlacesCompanion(
      id: Value(p.id),
      userId: Value(p.userId),
      name: Value(p.name),
      type: Value(p.type.name),
      latitude: Value(p.latitude),
      longitude: Value(p.longitude),
      radius: Value(p.radius),
      visitCount: Value(p.visitCount),
      totalSpendMinor: Value(p.totalSpendMinor),
      lastVisitedAt: Value(p.lastVisitedAt),
      createdAt: Value(p.createdAt),
      updatedAt: Value(p.updatedAt),
      deletedAt: Value(p.deletedAt),
      syncStatus: Value(p.syncStatus.name),
      deviceId: Value(p.deviceId),
      version: Value(p.version),
    );

Person personFromRow(PersonData row) => Person(
      id: row.id,
      userId: row.userId,
      name: row.name,
      phone: row.phone,
      note: row.note,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      syncStatus: SyncStatus.values.byName(row.syncStatus),
      deviceId: row.deviceId,
      version: row.version,
    );

PeopleCompanion personToRow(Person p) => PeopleCompanion(
      id: Value(p.id),
      userId: Value(p.userId),
      name: Value(p.name),
      phone: Value(p.phone),
      note: Value(p.note),
      createdAt: Value(p.createdAt),
      updatedAt: Value(p.updatedAt),
      deletedAt: Value(p.deletedAt),
      syncStatus: Value(p.syncStatus.name),
      deviceId: Value(p.deviceId),
      version: Value(p.version),
    );

LedgerEntry ledgerFromRow(LedgerEntryData row) => LedgerEntry(
      id: row.id,
      userId: row.userId,
      personId: row.personId,
      amount: Money(minorUnits: row.amountMinor, currencyCode: row.currencyCode),
      direction: LedgerDirection.values.byName(row.direction),
      type: LedgerType.values.byName(row.type),
      date: row.date,
      note: row.note,
      relatedExpenseId: row.relatedExpenseId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      syncStatus: SyncStatus.values.byName(row.syncStatus),
      deviceId: row.deviceId,
      version: row.version,
    );

LedgerEntriesCompanion ledgerToRow(LedgerEntry e) => LedgerEntriesCompanion(
      id: Value(e.id),
      userId: Value(e.userId),
      personId: Value(e.personId),
      amountMinor: Value(e.amount.minorUnits),
      currencyCode: Value(e.amount.currencyCode),
      direction: Value(e.direction.name),
      type: Value(e.type.name),
      date: Value(e.date),
      note: Value(e.note),
      relatedExpenseId: Value(e.relatedExpenseId),
      createdAt: Value(e.createdAt),
      updatedAt: Value(e.updatedAt),
      deletedAt: Value(e.deletedAt),
      syncStatus: Value(e.syncStatus.name),
      deviceId: Value(e.deviceId),
      version: Value(e.version),
    );

ExpenseOpportunity opportunityFromRow(OpportunityData row) =>
    ExpenseOpportunity(
      id: row.id,
      userId: row.userId,
      placeId: row.placeId,
      detectedAt: row.detectedAt,
      visitStartedAt: row.visitStartedAt,
      visitEndedAt: row.visitEndedAt,
      durationSeconds: row.durationSeconds,
      distanceFromPreviousPlace: row.distanceFromPreviousPlace,
      confidenceScore: row.confidenceScore,
      suggestedCategoryId: row.suggestedCategoryId,
      suggestedMerchantName: row.suggestedMerchantName,
      status: OpportunityStatus.values.byName(row.status),
      notificationId: row.notificationId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      syncStatus: SyncStatus.values.byName(row.syncStatus),
      deviceId: row.deviceId,
      version: row.version,
    );

OpportunitiesCompanion opportunityToRow(ExpenseOpportunity o) =>
    OpportunitiesCompanion(
      id: Value(o.id),
      userId: Value(o.userId),
      placeId: Value(o.placeId),
      detectedAt: Value(o.detectedAt),
      visitStartedAt: Value(o.visitStartedAt),
      visitEndedAt: Value(o.visitEndedAt),
      durationSeconds: Value(o.durationSeconds),
      distanceFromPreviousPlace: Value(o.distanceFromPreviousPlace),
      confidenceScore: Value(o.confidenceScore),
      suggestedCategoryId: Value(o.suggestedCategoryId),
      suggestedMerchantName: Value(o.suggestedMerchantName),
      status: Value(o.status.name),
      notificationId: Value(o.notificationId),
      createdAt: Value(o.createdAt),
      updatedAt: Value(o.updatedAt),
      deletedAt: Value(o.deletedAt),
      syncStatus: Value(o.syncStatus.name),
      deviceId: Value(o.deviceId),
      version: Value(o.version),
    );

AppSettings settingsFromJson(String userId, String json) {
  final map = jsonDecode(json) as Map<String, dynamic>;
  return AppSettings(
    userId: userId,
    currencyCode: map['currencyCode'] as String? ?? AppConstants.defaultCurrency,
    promptStyle: PromptStyle.values.byName(map['promptStyle'] as String? ?? 'smart'),
    minStopMinutes: map['minStopMinutes'] as int? ?? 3,
    askAfterLeaving: map['askAfterLeaving'] as bool? ?? true,
    askAfterReturningHome: map['askAfterReturningHome'] as bool? ?? true,
    eveningReview: map['eveningReview'] as bool? ?? true,
    maxDailyPrompts: map['maxDailyPrompts'] as int? ?? 8,
    themeMode: map['themeMode'] as String? ?? 'system',
    onboardingComplete: map['onboardingComplete'] as bool? ?? false,
    homePlaceId: map['homePlaceId'] as String?,
    workPlaceId: map['workPlaceId'] as String?,
    backgroundLocation: map['backgroundLocation'] as bool? ?? true,
    smartPlaceDetection: map['smartPlaceDetection'] as bool? ?? true,
    homeDetection: map['homeDetection'] as bool? ?? true,
    workDetection: map['workDetection'] as bool? ?? true,
    expensePrompts: map['expensePrompts'] as bool? ?? true,
    quietHoursStart: map['quietHoursStart'] as int? ?? 22,
    quietHoursEnd: map['quietHoursEnd'] as int? ?? 7,
    placeCooldownHours: map['placeCooldownHours'] as int? ?? 4,
    lastCategoryId: map['lastCategoryId'] as String?,
    lastPaymentMethod: _payment(map['lastPaymentMethod'] as String? ?? 'upi'),
    scoring: ScoringConfig(
      weights: (map['weights'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          ) ??
          const {},
      ignoreBelow: map['ignoreBelow'] as int? ?? 40,
      lowBelow: map['lowBelow'] as int? ?? 60,
      possibleBelow: map['possibleBelow'] as int? ?? 75,
    ),
  );
}

String settingsToJson(AppSettings s) => jsonEncode({
      'currencyCode': s.currencyCode,
      'promptStyle': s.promptStyle.name,
      'minStopMinutes': s.minStopMinutes,
      'askAfterLeaving': s.askAfterLeaving,
      'askAfterReturningHome': s.askAfterReturningHome,
      'eveningReview': s.eveningReview,
      'maxDailyPrompts': s.maxDailyPrompts,
      'themeMode': s.themeMode,
      'onboardingComplete': s.onboardingComplete,
      'homePlaceId': s.homePlaceId,
      'workPlaceId': s.workPlaceId,
      'backgroundLocation': s.backgroundLocation,
      'smartPlaceDetection': s.smartPlaceDetection,
      'homeDetection': s.homeDetection,
      'workDetection': s.workDetection,
      'expensePrompts': s.expensePrompts,
      'quietHoursStart': s.quietHoursStart,
      'quietHoursEnd': s.quietHoursEnd,
      'placeCooldownHours': s.placeCooldownHours,
      'lastCategoryId': s.lastCategoryId,
      'lastPaymentMethod': s.lastPaymentMethod.name,
      'weights': s.scoring.weights,
      'ignoreBelow': s.scoring.ignoreBelow,
      'lowBelow': s.scoring.lowBelow,
      'possibleBelow': s.scoring.possibleBelow,
    });

PaymentMethod _payment(String name) {
  for (final v in PaymentMethod.values) {
    if (v.name == name) return v;
  }
  return PaymentMethod.notSpecified;
}
