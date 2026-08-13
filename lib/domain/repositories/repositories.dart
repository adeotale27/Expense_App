import '../entities/entities.dart';
import '../enums/enums.dart';

class ExpenseQuery {
  const ExpenseQuery({
    this.from,
    this.to,
    this.categoryId,
    this.placeId,
    this.paymentMethod,
    this.search,
    this.minAmountMinor,
    this.maxAmountMinor,
    this.sort = ExpenseSort.newest,
    this.limit = 50,
    this.offset = 0,
  });

  final DateTime? from;
  final DateTime? to;
  final String? categoryId;
  final String? placeId;
  final PaymentMethod? paymentMethod;
  final String? search;
  final int? minAmountMinor;
  final int? maxAmountMinor;
  final ExpenseSort sort;
  final int limit;
  final int offset;
}

enum ExpenseSort { newest, oldest, highest, lowest }

abstract class ExpenseRepository {
  Stream<List<Expense>> watchRecent({int limit = 50});
  Future<List<Expense>> list(ExpenseQuery query);
  Future<Expense?> getById(String id);
  Future<void> upsert(Expense expense);
  Future<void> softDelete(String id, DateTime deletedAt);
  Future<int> sumMinor({required DateTime from, required DateTime to});
  Future<Map<String, int>> sumByCategory(
      {required DateTime from, required DateTime to});
  Future<List<Expense>> pendingSync();
}

abstract class CategoryRepository {
  Stream<List<Category>> watchActive();
  Future<List<Category>> all();
  Future<void> upsert(Category category);
  Future<Category?> byName(String name);
}

abstract class PlaceRepository {
  Stream<List<Place>> watchAll();
  Future<List<Place>> all();
  Future<Place?> getById(String id);
  Future<Place?> findNearby(double lat, double lng, {double maxMeters = 80});
  Future<void> upsert(Place place);
}

abstract class PersonRepository {
  Stream<List<Person>> watchAll();
  Future<Person?> getById(String id);
  Future<void> upsert(Person person);
  Future<void> softDelete(String id, DateTime deletedAt);
}

abstract class LedgerRepository {
  Stream<List<LedgerEntry>> watchForPerson(String personId);
  Future<List<LedgerEntry>> all();
  Future<void> add(LedgerEntry entry);
  Future<int> balanceMinorFor(String personId);
}

abstract class OpportunityRepository {
  Stream<List<ExpenseOpportunity>> watchPending();
  Future<List<ExpenseOpportunity>> pending();
  Future<void> upsert(ExpenseOpportunity opportunity);
  Future<bool> hasOpenForPlaceSince(String placeId, DateTime since);
}

abstract class SettingsRepository {
  Future<AppSettings> get(String userId);
  Future<void> save(AppSettings settings);
  Stream<AppSettings> watch(String userId);
}

abstract class RecurringRepository {
  Stream<List<RecurringExpense>> watchActive();
  Future<void> upsert(RecurringExpense item);
}
