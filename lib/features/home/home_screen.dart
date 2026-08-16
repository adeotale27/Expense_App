import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/haptics.dart';
import '../../app/providers.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/money.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/enums.dart';
import '../expenses/add_expense_screen.dart';
import '../habits/habit_engine.dart';
import '../shared/action_sheet.dart';
import '../shared/selection_grids.dart';
import '../shared/widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  var _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    final cats = ref.read(categoryRepoProvider);
    await cats.ensureDefaults();
    final settings = await ref.read(settingsRepoProvider).get(ref.read(userIdProvider));
    if (!settings.onboardingComplete) {
      await ref.read(settingsRepoProvider).save(settings.copyWith(onboardingComplete: true));
      if (mounted) await _maybeHome(settings);
    }
    try {
      await ref.read(syncEngineProvider).syncAll();
    } catch (_) {}
  }

  Future<void> _maybeHome(settings) async {
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
    final place = await ref.read(locationRuntimeReadyProvider).rememberUnknown(
          loc,
          'Home',
        );
    final latest = await ref.read(settingsRepoProvider).get(ref.read(userIdProvider));
    await ref.read(settingsRepoProvider).save(latest.copyWith(homePlaceId: place.id));
  }

  Future<void> _quick(int minor) async {
    AppHaptics.tap();
    if (!mounted) return;
    context.push('/add?amount=$minor');
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(locationRuntimeReadyProvider);
    final runtime = ref.read(locationRuntimeReadyProvider);
    final expenses = ref.watch(recentExpensesProvider).valueOrNull ?? [];
    final pending = ref.watch(pendingOpportunitiesProvider).valueOrNull ?? [];
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final placeList = ref.watch(placesProvider).valueOrNull ?? [];
    final places = {for (final p in placeList) p.id: p};
    final now = DateTime.now();
    final todayStart = startOfLocalDay(now);
    int today = 0;
    final todayItems = <Expense>[];
    for (final e in expenses) {
      final local = e.timestamp.toLocal();
      if (!local.isBefore(todayStart)) {
        today += e.amount.minorUnits;
        todayItems.add(e);
      }
    }
    todayItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final catMap = {for (final c in cats) c.id: c};
    final habits = HabitEngine().learn(
      expenses: expenses,
      places: placeList,
      visits: const [],
    );
    final suggestion = runtime.pendingSuggestion;
    final topOpp = pending.isEmpty ? null : pending.first;
    final place = topOpp == null ? null : places[topOpp.placeId];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      greetingFor(now),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Search expenses',
                    onPressed: () => context.push('/search'),
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
              QuietCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TODAY', style: Theme.of(context).textTheme.labelMedium),
                    MoneyText(Money(minorUnits: today), large: true),
                    Text(
                      '${todayItems.length} expense${todayItems.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              QuickAmountRow(
                minors: habits.typicalQuickAmounts,
                onAmount: _quick,
                onCustom: () => context.push('/add'),
              ),
              if (suggestion != null) ...[
                const SizedBox(height: 12),
                _PromptCard(
                  title: suggestion.headline,
                  body: suggestion.body,
                  onYes: () async {
                    await runtime.answerSuggestion(suggestion, true);
                    setState(() {});
                  },
                  onNo: () async {
                    await runtime.answerSuggestion(suggestion, false);
                    setState(() {});
                  },
                ),
              ] else if (topOpp != null) ...[
                const SizedBox(height: 12),
                _PromptCard(
                  title: '📍 ${place?.name ?? topOpp.suggestedMerchantName ?? 'A place'}',
                  body: 'Did you spend anything here?',
                  onYes: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddExpenseScreen(opportunity: topOpp),
                      ),
                    );
                  },
                  onNo: () async {
                    await ref.read(opportunityRepoProvider).upsert(
                          topOpp.copyWith(
                            status: OpportunityStatus.nothingSpent,
                            updatedAt: DateTime.now().toUtc(),
                          ),
                        );
                  },
                ),
              ],
              const SizedBox(height: 12),
              Text('Recent', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Expanded(
                child: todayItems.isEmpty
                    ? const EmptyState(
                        title: 'Nothing yet today',
                        subtitle: 'Tap a quick amount to record a spend in seconds.',
                      )
                    : ListView.builder(
                        itemCount: todayItems.length.clamp(0, 8),
                        itemBuilder: (context, i) {
                          final e = todayItems[i];
                          final cat = catMap[e.categoryId];
                          return _ExpenseTile(
                            expense: e,
                            category: cat,
                            onTap: () => context.push('/expenses/${e.id}'),
                            onLongPress: () => _expenseActions(e),
                          );
                        },
                      ),
              ),
            ],
          ),
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

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.title,
    required this.body,
    required this.onYes,
    required this.onNo,
  });
  final String title;
  final String body;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    return QuietCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(body),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: FilledButton(onPressed: onYes, child: const Text('Yes'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: onNo, child: const Text('Not this time'))),
            ],
          ),
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
        backgroundColor: Color((category?.accentColor ?? 0xFF6D5EF7)).withValues(alpha: 0.18),
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
