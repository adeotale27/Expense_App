import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/dates.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/enums.dart';
import '../../domain/repositories/repositories.dart';
import '../shared/action_sheet.dart';
import '../shared/widgets.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  String range = 'Month';
  String? categoryId;
  PaymentMethod? method;
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
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final catMap = {for (final c in cats) c.id: c};
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spends'),
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in ['Today', 'Week', 'Month'])
                  ChoiceChip(
                    label: Text(r),
                    selected: range == r,
                    onSelected: (_) => setState(() => range = r),
                  ),
                for (final c in cats.take(6))
                  ChoiceChip(
                    label: Text('${c.icon} ${c.name}'),
                    selected: categoryId == c.id,
                    onSelected: (_) => setState(() => categoryId = categoryId == c.id ? null : c.id),
                  ),
                for (final m in [PaymentMethod.upi, PaymentMethod.cash])
                  ChoiceChip(
                    label: Text(m.label),
                    selected: method == m,
                    onSelected: (_) => setState(() => method = method == m ? null : m),
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
                      categoryId: categoryId,
                      paymentMethod: method,
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
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 108),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final e = items[i];
                    final cat = catMap[e.categoryId];
                    return QuietCard(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      onTap: () => context.push('/expenses/${e.id}'),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        leading: CircleAvatar(
                          backgroundColor: Color(cat?.accentColor ?? 0xFF0FBE8F).withValues(alpha: 0.18),
                          child: Text(cat?.icon ?? '•'),
                        ),
                        title: Text(
                          cat?.name ?? 'Expense',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${formatDay(e.timestamp.toLocal())} · ${formatTime(e.timestamp.toLocal())}',
                        ),
                        trailing: Text(
                          e.amount.format(),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        onLongPress: () => _actions(e),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _actions(Expense e) async {
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
      setState(() {});
    }
    if (action == 'del') {
      await ref.read(expenseRepoProvider).softDelete(e.id, DateTime.now().toUtc());
      setState(() {});
    }
  }
}
