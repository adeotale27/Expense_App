import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/utils/dates.dart';
import '../../domain/repositories/repositories.dart';
import '../shared/widgets.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  String range = 'Month';
  ExpenseSort sort = ExpenseSort.newest;
  String search = '';

  DateTimeRange _bounds() {
    final now = DateTime.now();
    return switch (range) {
      'Today' => DateTimeRange(start: startOfLocalDay(now), end: endOfLocalDay(now)),
      'Week' => DateTimeRange(
          start: startOfLocalDay(now.subtract(Duration(days: now.weekday - 1))),
          end: endOfLocalDay(now),
        ),
      _ => DateTimeRange(start: startOfLocalMonth(now), end: endOfLocalDay(now)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cats = {for (final c in ref.watch(categoriesProvider).valueOrNull ?? []) c.id: c};
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                for (final r in ['Today', 'Week', 'Month'])
                  ChoiceChip(
                    label: Text(r),
                    selected: range == r,
                    onSelected: (_) => setState(() => range = r),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: ref.read(expenseRepoProvider).list(
                    ExpenseQuery(
                      from: _bounds().start,
                      to: _bounds().end,
                      search: search,
                      sort: sort,
                    ),
                  ),
              builder: (context, snap) {
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const EmptyState(
                    title: 'No expenses',
                    subtitle: 'Add one from Home — it works offline.',
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final e = items[i];
                    final cat = cats[e.categoryId];
                    return ListTile(
                      title: Text('${cat?.icon ?? ''} ${cat?.name ?? 'Expense'}'.trim()),
                      subtitle: Text(
                        '${formatDay(e.timestamp.toLocal())} · ${formatTime(e.timestamp.toLocal())}',
                      ),
                      trailing: Text(
                        e.amount.format(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onTap: () => context.push('/expenses/${e.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
