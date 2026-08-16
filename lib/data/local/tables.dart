import 'package:drift/drift.dart';

@DataClassName('ExpenseData')
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currencyCode => text().withDefault(const Constant('INR'))();
  TextColumn get categoryId => text()();
  TextColumn get merchantName => text().nullable()();
  TextColumn get placeId => text().nullable()();
  TextColumn get paymentMethod =>
      text().withDefault(const Constant('notSpecified'))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get source => text()();
  TextColumn get opportunityId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get deviceId => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CategoryData')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get deviceId => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PlaceData')
class Places extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get radius => real().withDefault(const Constant(80))();
  IntColumn get visitCount => integer().withDefault(const Constant(0))();
  IntColumn get totalSpendMinor => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastVisitedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get deviceId => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PersonData')
class People extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get deviceId => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('LedgerEntryData')
class LedgerEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get personId => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currencyCode => text().withDefault(const Constant('INR'))();
  TextColumn get direction => text()();
  TextColumn get type => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get relatedExpenseId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get deviceId => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('OpportunityData')
class Opportunities extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get placeId => text().nullable()();
  DateTimeColumn get detectedAt => dateTime()();
  DateTimeColumn get visitStartedAt => dateTime()();
  DateTimeColumn get visitEndedAt => dateTime().nullable()();
  IntColumn get durationSeconds => integer()();
  RealColumn get distanceFromPreviousPlace => real().nullable()();
  IntColumn get confidenceScore => integer()();
  TextColumn get suggestedCategoryId => text().nullable()();
  TextColumn get suggestedMerchantName => text().nullable()();
  TextColumn get status => text()();
  TextColumn get notificationId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get deviceId => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('RecurringExpenseData')
class RecurringExpenses extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currencyCode => text().withDefault(const Constant('INR'))();
  TextColumn get frequency => text()();
  TextColumn get categoryId => text()();
  DateTimeColumn get nextExpectedDate => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get deviceId => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SettingsData')
class SettingsRows extends Table {
  TextColumn get userId => text()();
  TextColumn get json => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

@DataClassName('LocalAccountData')
class LocalAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get passwordHash => text()();
  TextColumn get salt => text()();
  TextColumn get displayName => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('RawLocationData')
class RawLocationPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get accuracy => real().nullable()();
  DateTimeColumn get capturedAt => dateTime()();
}
