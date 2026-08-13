import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../shared/widgets.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final expenses = (ref.watch(recentExpensesProvider).valueOrNull ?? [])
        .where((e) => !e.timestamp.toLocal().isBefore(startOfLocalMonth(now)))
        .toList();
    final cats = {for (final c in ref.watch(categoriesProvider).valueOrNull ?? []) c.id: c};
    final places = {for (final p in ref.watch(placesProvider).valueOrNull ?? []) p.id: p};
    final total = expenses.fold<int>(0, (p, e) => p + e.amount.minorUnits);
    final days = now.day.clamp(1, 31);
    final byCat = <String, int>{};
    final byDay = <int, int>{};
    for (final e in expenses) {
      byCat[e.categoryId] = (byCat[e.categoryId] ?? 0) + e.amount.minorUnits;
      byDay[e.timestamp.toLocal().day] =
          (byDay[e.timestamp.toLocal().day] ?? 0) + e.amount.minorUnits;
    }
    final ranked = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final highestDay = byDay.entries.isEmpty
        ? null
        : byDay.entries.reduce((a, b) => a.value >= b.value ? a : b);

    return Scaffold(
      appBar: AppBar(title: Text(monthTitle(now))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          QuietCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MoneyText(Money(minorUnits: total), large: true),
                Text('Average per day: ${Money(minorUnits: total ~/ days).format()}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Categories', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final e in ranked)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${cats[e.key]?.icon ?? ''} ${cats[e.key]?.name ?? 'Other'}'.trim()),
              trailing: Text(Money(minorUnits: e.value).format()),
            ),
          const SizedBox(height: 16),
          Text('Insights', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (expenses.isEmpty)
            const Text('Insights appear after you record real expenses.')
          else ...[
            if (highestDay != null)
              Text('Day ${highestDay.key} was your highest spending day.'),
            if (ranked.isNotEmpty)
              Text(
                'Most of your spending this month is ${cats[ranked.first.key]?.name ?? 'other'}.',
              ),
            Text('You recorded ${expenses.length} expenses this month.'),
          ],
          const SizedBox(height: 16),
          Text('Places', style: Theme.of(context).textTheme.titleMedium),
          for (final p in places.values.take(8))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(p.name),
              trailing: Text(Money(minorUnits: p.totalSpendMinor).format()),
            ),
        ],
      ),
    );
  }
}
