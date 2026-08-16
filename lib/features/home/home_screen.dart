import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/haptics.dart';
import '../../app/providers.dart';
import '../../app/quick_spend.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/money.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/enums.dart';
import '../../location/location_service.dart';
import '../expenses/add_expense_screen.dart';
import '../habits/habit_engine.dart';
import '../shared/action_sheet.dart';
import '../shared/selection_grids.dart';
import '../shared/widgets.dart';

int? _lastPublishedToday;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  var _bootstrapped = false;
  final amount = TextEditingController();
  String? categoryId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    Future.microtask(_bootstrap);
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await ref.read(categoryRepoProvider).ensureDefaults();
    await importWidgetInbox(ref);
    final settings = await ref.read(settingsRepoProvider).get(ref.read(userIdProvider));
    if (!settings.onboardingComplete) {
      await ref.read(settingsRepoProvider).save(settings.copyWith(onboardingComplete: true));
      if (mounted) await _maybeHome();
    }
    try {
      await ref.read(syncEngineProvider).syncAll();
    } catch (_) {}
  }

  Future<void> _maybeHome() async {
    final go = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Make SpendPing smarter', style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text("Where's home? Optional — skip and we'll learn from evenings you spend in the same place."),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Detect current location'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Skip for now'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (go != true) return;
    final loc = await ref.read(locationProviderAdapter).getCurrentLocation();
    if (loc == null) return;
    final place = await ref.read(locationRuntimeReadyProvider).rememberUnknown(loc, 'Home');
    final latest = await ref.read(settingsRepoProvider).get(ref.read(userIdProvider));
    await ref.read(settingsRepoProvider).save(latest.copyWith(homePlaceId: place.id));
  }

  double get major => double.tryParse(amount.text.trim()) ?? 0;

  Future<void> _enableLocation() async {
    final ok = await ref.read(locationProviderAdapter).requestPermission();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is needed for visit pings.')),
        );
      }
      return;
    }
    await ref.read(notificationServiceProvider).requestPermission();
    final settings = await ref.read(settingsRepoProvider).get(ref.read(userIdProvider));
    await ref.read(settingsRepoProvider).save(
          settings.copyWith(
            backgroundLocation: true,
            smartPlaceDetection: true,
          ),
        );
    await ref.read(locationRuntimeReadyProvider).restart();
    if (mounted) setState(() {});
  }

  Future<void> _recordQuick() async {
    if (major <= 0) return;
    final cats = ref.read(categoriesProvider).valueOrNull ?? [];
    final settings = ref.read(settingsProvider).valueOrNull;
    final expenses = ref.read(recentExpensesProvider).valueOrNull ?? [];
    final placeList = ref.read(placesProvider).valueOrNull ?? [];
    final habits = HabitEngine().learn(
      expenses: expenses,
      places: placeList,
      visits: const [],
      settings: settings,
    );
    final catId = categoryId ??
        habits.recentCategoryId ??
        habits.frequentCategoryId ??
        settings?.lastCategoryId ??
        cats.where((c) => c.name == 'Other').firstOrNull?.id ??
        (cats.isNotEmpty ? cats.first.id : null);
    if (catId == null) return;
    final recorded = Money.fromMajor(major);
    AppHaptics.confirm();
    final now = DateTime.now().toUtc();
    await ref.read(expenseRepoProvider).upsert(
          Expense(
            id: newId(),
            userId: ref.read(userIdProvider),
            amount: recorded,
            categoryId: catId,
            paymentMethod: settings?.lastPaymentMethod ?? PaymentMethod.upi,
            timestamp: now,
            createdAt: now,
            updatedAt: now,
            deviceId: ref.read(deviceIdProvider),
          ),
        );
    await ref.read(settingsRepoProvider).save(
          (settings ?? AppSettings(userId: ref.read(userIdProvider))).copyWith(
            lastCategoryId: catId,
          ),
        );
    amount.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recorded ${recorded.format()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(locationPulseProvider);
    ref.watch(locationRuntimeReadyProvider);
    final runtime = ref.read(locationRuntimeReadyProvider);
    final expenses = ref.watch(todayExpensesProvider).valueOrNull ?? [];
    final pending = ref.watch(pendingOpportunitiesProvider).valueOrNull ?? [];
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final placeList = ref.watch(placesProvider).valueOrNull ?? [];
    final places = {for (final p in placeList) p.id: p};
    final now = DateTime.now();
    final todayItems = [...expenses]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final today = todayItems.fold<int>(0, (p, e) => p + e.amount.minorUnits);
    if (_lastPublishedToday != today) {
      _lastPublishedToday = today;
      publishTodayTotal(today);
    }
    final catMap = {for (final c in cats) c.id: c};
    final recent = ref.watch(recentExpensesProvider).valueOrNull ?? [];
    final settings = ref.watch(settingsProvider).valueOrNull;
    final habits = HabitEngine().learn(
      expenses: recent,
      places: placeList,
      visits: const [],
      settings: settings,
    );
    final selectedCat = categoryId ?? habits.recentCategoryId ?? habits.frequentCategoryId;
    final suggestion = runtime.pendingSuggestion;
    final topOpp = pending.isEmpty ? null : pending.first;
    final place = topOpp == null ? null : places[topOpp.placeId];
    final here = runtime.currentPlace;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 108),
          children: [
            Text(
              greetingFor(now),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            GradientHero(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TODAY', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => context.push('/add'),
                    child: MoneyText(
                      Money(minorUnits: today),
                      style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                  Text('${todayItems.length} spends · tap to add'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _LocationCard(
              runtime: runtime,
              here: here,
              suggestion: suggestion,
              topOpp: topOpp,
              place: place,
              onEnable: _enableLocation,
            ),
            const SizedBox(height: 14),
            QuietCard(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Type an amount', style: Theme.of(context).textTheme.titleSmall),
                  AmountField(
                    controller: amount,
                    large: false,
                    autofocus: false,
                    onChanged: (_) => setState(() {}),
                  ),
                  QuickAmountRow(
                    minors: habits.typicalQuickAmounts,
                    onAmount: (m) => setState(() {
                      amount.text = '${(m / 100).round()}';
                      amount.selection = TextSelection.collapsed(offset: amount.text.length);
                    }),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final c in cats.take(8))
                        ChoiceChip(
                          label: Text('${c.icon} ${c.name}'),
                          selected: (categoryId ?? selectedCat) == c.id,
                          onSelected: (_) => setState(() => categoryId = c.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: major > 0 ? _recordQuick : null,
                    child: Text(major > 0 ? 'Record ₹${amount.text}' : 'Enter an amount'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text("Today's spends", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (todayItems.isEmpty)
              const Text('Nothing yet today. Type an amount above — it takes a second.')
            else
              for (final e in todayItems)
                _ExpenseTile(
                  expense: e,
                  category: catMap[e.categoryId],
                  onTap: () => context.push('/expenses/${e.id}'),
                  onLongPress: () => _expenseActions(e),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _expenseActions(Expense e) async {
    final action = await showActionSheet<String>(
      context,
      title: e.amount.format(),
      actions: const [
        SheetAction('Edit', 'edit', icon: Icons.edit_outlined),
        SheetAction('Duplicate', 'dup', icon: Icons.copy_outlined),
        SheetAction('Delete', 'del', icon: Icons.delete_outline, destructive: true),
      ],
    );
    if (action == 'edit' && mounted) context.push('/expenses/${e.id}');
    if (action == 'dup') {
      final now = DateTime.now().toUtc();
      await ref.read(expenseRepoProvider).upsert(
            Expense(
              id: newId(),
              userId: e.userId,
              amount: e.amount,
              categoryId: e.categoryId,
              merchantName: e.merchantName,
              placeId: e.placeId,
              paymentMethod: e.paymentMethod,
              note: e.note,
              timestamp: now,
              source: ExpenseSource.manual,
              createdAt: now,
              updatedAt: now,
              deviceId: e.deviceId,
            ),
          );
    }
    if (action == 'del') {
      await ref.read(expenseRepoProvider).softDelete(e.id, DateTime.now().toUtc());
    }
  }
}

class _LocationCard extends ConsumerWidget {
  const _LocationCard({
    required this.runtime,
    required this.here,
    required this.suggestion,
    required this.topOpp,
    required this.place,
    required this.onEnable,
  });

  final LocationRuntime runtime;
  final Place? here;
  final PlaceSuggestion? suggestion;
  final ExpenseOpportunity? topOpp;
  final Place? place;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listening = runtime.permissionGranted || runtime.monitoring;
    if (!listening && here == null && suggestion == null && topOpp == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        leading: const Icon(Icons.place_outlined),
        title: const Text('Visit pings'),
        subtitle: const Text('Optional. GPS never records a spend.'),
        trailing: TextButton(
          onPressed: onEnable,
          child: const Text('Enable'),
        ),
      );
    }

    if (suggestion == null && topOpp == null) {
      if (here == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          'At ${here!.name}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    final title = suggestion?.headline ??
        'Left ${place?.name ?? topOpp?.suggestedMerchantName ?? 'a place'}';
    final body = suggestion?.body ?? 'Did you spend anything?';

    return QuietCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(body),
          if (suggestion != null || topOpp != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      if (suggestion != null) {
                        await runtime.answerSuggestion(suggestion!, true);
                      } else if (topOpp != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddExpenseScreen(opportunity: topOpp),
                          ),
                        );
                      }
                    },
                    child: const Text('Yes, record it'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      if (suggestion != null) {
                        await runtime.answerSuggestion(suggestion!, false);
                      } else if (topOpp != null) {
                        await ref.read(opportunityRepoProvider).upsert(
                              topOpp!.copyWith(
                                status: OpportunityStatus.nothingSpent,
                                updatedAt: DateTime.now().toUtc(),
                              ),
                            );
                      }
                    },
                    child: const Text('Not this time'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.category,
    required this.onTap,
    required this.onLongPress,
  });
  final Expense expense;
  final Category? category;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Color(category?.accentColor ?? 0xFF0FBE8F).withValues(alpha: 0.18),
        child: Text(category?.icon ?? '•'),
      ),
      title: Text(category?.name ?? expense.merchantName ?? 'Expense'),
      subtitle: Text(formatTime(expense.timestamp.toLocal())),
      trailing: Text(
        expense.amount.format(),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
