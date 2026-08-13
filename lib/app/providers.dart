import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/remote/auth_service.dart';
import '../data/repositories/drift_repositories.dart';
import '../data/sync/sync_engine.dart';
import '../domain/entities/entities.dart';
import '../domain/repositories/repositories.dart';
import '../location/location_provider.dart';
import '../location/location_service.dart';
import '../notifications/notification_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError();
});

final sessionProfileProvider = StateProvider<UserProfile?>((ref) => null);

final deviceIdProvider = Provider<String>((ref) {
  throw UnimplementedError();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(databaseProvider), SessionStore());
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError();
});

final simulatorProvider = Provider<SimulatedLocationProvider>((ref) {
  throw UnimplementedError();
});

final locationProviderAdapter = Provider<LocationProvider>((ref) {
  throw UnimplementedError();
});

final remoteStoreProvider = Provider<RemoteStore>((ref) {
  throw UnimplementedError();
});

final userIdProvider = Provider<String>((ref) {
  final user = ref.watch(sessionProfileProvider);
  if (user == null) {
    throw StateError('Not signed in');
  }
  return user.id;
});

final expenseRepoProvider = Provider<DriftExpenseRepository>((ref) {
  return DriftExpenseRepository(ref.watch(databaseProvider), ref.watch(userIdProvider));
});

final categoryRepoProvider = Provider<DriftCategoryRepository>((ref) {
  return DriftCategoryRepository(
    ref.watch(databaseProvider),
    ref.watch(userIdProvider),
    ref.watch(deviceIdProvider),
  );
});

final placeRepoProvider = Provider<PlaceRepository>((ref) {
  return DriftPlaceRepository(ref.watch(databaseProvider), ref.watch(userIdProvider));
});

final personRepoProvider = Provider<PersonRepository>((ref) {
  return DriftPersonRepository(ref.watch(databaseProvider), ref.watch(userIdProvider));
});

final ledgerRepoProvider = Provider<LedgerRepository>((ref) {
  return DriftLedgerRepository(ref.watch(databaseProvider), ref.watch(userIdProvider));
});

final opportunityRepoProvider = Provider<OpportunityRepository>((ref) {
  return DriftOpportunityRepository(
    ref.watch(databaseProvider),
    ref.watch(userIdProvider),
  );
});

final settingsRepoProvider = Provider<SettingsRepository>((ref) {
  return DriftSettingsRepository(ref.watch(databaseProvider));
});

final recurringRepoProvider = Provider<RecurringRepository>((ref) {
  return DriftRecurringRepository(
    ref.watch(databaseProvider),
    ref.watch(userIdProvider),
  );
});

final settingsProvider = StreamProvider<AppSettings>((ref) {
  return ref.watch(settingsRepoProvider).watch(ref.watch(userIdProvider));
});

final recentExpensesProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(expenseRepoProvider).watchRecent(limit: 80);
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepoProvider).watchActive();
});

final placesProvider = StreamProvider<List<Place>>((ref) {
  return ref.watch(placeRepoProvider).watchAll();
});

final peopleProvider = StreamProvider<List<Person>>((ref) {
  return ref.watch(personRepoProvider).watchAll();
});

final pendingOpportunitiesProvider = StreamProvider<List<ExpenseOpportunity>>((ref) {
  return ref.watch(opportunityRepoProvider).watchPending();
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    db: ref.watch(databaseProvider),
    userId: ref.watch(userIdProvider),
    remote: ref.watch(remoteStoreProvider),
  );
});

final locationRuntimeReadyProvider = Provider<LocationRuntime>((ref) {
  final runtime = LocationRuntime(
    userId: ref.watch(userIdProvider),
    deviceId: ref.watch(deviceIdProvider),
    places: ref.watch(placeRepoProvider),
    opportunities: ref.watch(opportunityRepoProvider),
    categories: ref.watch(categoryRepoProvider),
    settingsRepo: ref.watch(settingsRepoProvider),
    notifications: ref.watch(notificationServiceProvider),
    provider: ref.watch(locationProviderAdapter),
    simulator: ref.watch(simulatorProvider),
  );
  Future<void>.microtask(runtime.start);
  ref.onDispose(runtime.stop);
  return runtime;
});
