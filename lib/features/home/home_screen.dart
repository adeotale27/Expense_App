import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../domain/entities/entities.dart';
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
    }
    try {
      await ref.read(syncEngineProvider).syncAll();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(locationRuntimeReadyProvider);
    final user = ref.watch(sessionProfileProvider);
    final expenses = ref.watch(recentExpensesProvider).valueOrNull ?? [];
    final pending = ref.watch(pendingOpportunitiesProvider).valueOrNull ?? [];
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final now = DateTime.now();
    final todayStart = startOfLocalDay(now);
    final monthStart = startOfLocalMonth(now);
    int today = 0;
    int month = 0;
    final todayItems = <Expense>[];
    for (final e in expenses) {
      final local = e.timestamp.toLocal();
      if (!local.isBefore(todayStart)) {
        today += e.amount.minorUnits;
        todayItems.add(e);
      }
      if (!local.isBefore(monthStart)) {
        month += e.amount.minorUnits;
      }
    }
    todayItems.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final catMap = {for (final c in cats) c.id: c};

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${greetingFor(now)} 👋',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push('/search'),
                      icon: const Icon(Icons.search),
                    ),
                  ],
                ),
              ),
            ),
            if (user != null)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    user.displayName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              sliver: SliverToBoxAdapter(
                child: QuietCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TODAY',
                          style: Theme.of(context).textTheme.labelMedium),
                      MoneyText(
                        Money(minorUnits: today),
                        large: true,
                      ),
                      const SizedBox(height: 16),
                      Text('THIS MONTH',
                          style: Theme.of(context).textTheme.labelMedium),
                      Text(
                        Money(minorUnits: month).format(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (pending.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                sliver: SliverToBoxAdapter(
                  child: QuietCard(
                    onTap: () => context.push('/inbox'),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_active_outlined,
                            color: Theme.of(context).colorScheme.tertiary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${pending.length} expense${pending.length == 1 ? '' : 's'} to review',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  "Today's Activity",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            if (todayItems.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Nothing recorded yet. Add an expense when you spend.'),
                ),
              )
            else
              SliverList.builder(
                itemCount: todayItems.length,
                itemBuilder: (context, i) {
                  final e = todayItems[i];
                  final cat = catMap[e.categoryId];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    title: Text(cat?.name ?? e.merchantName ?? 'Expense'),
                    subtitle: Text(formatTime(e.timestamp.toLocal())),
                    trailing: Text(
                      e.amount.format(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onTap: () => context.push('/expenses/${e.id}'),
                  );
                },
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 88)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }
}
