import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/utils/dates.dart';
import '../../domain/enums/enums.dart';
import '../../domain/repositories/repositories.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String q = '';
  String range = 'Month';
  String? categoryId;
  PaymentMethod? method;

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
    final people = ref.watch(peopleProvider).valueOrNull ?? [];
    final places = ref.watch(placesProvider).valueOrNull ?? [];
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search expenses',
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: (v) => setState(() => q = v.trim().toLowerCase()),
        ),
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
                for (final c in cats.take(4))
                  ChoiceChip(
                    label: Text(c.name),
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
            child: q.isEmpty && categoryId == null && method == null
                ? const Center(child: Text('Try Starbucks, grocery, UPI, ₹500'))
                : FutureBuilder(
                    future: ref.read(expenseRepoProvider).list(
                          ExpenseQuery(
                            search: q,
                            limit: 50,
                            from: _bounds().start,
                            to: _bounds().end,
                            categoryId: categoryId,
                            paymentMethod: method,
                          ),
                        ),
                    builder: (context, snap) {
                      final expenses = snap.data ?? [];
                      final matchedPeople =
                          people.where((p) => p.name.toLowerCase().contains(q)).toList();
                      final matchedPlaces =
                          places.where((p) => p.name.toLowerCase().contains(q)).toList();
                      return ListView(
                        children: [
                          if (matchedPeople.isNotEmpty)
                            const ListTile(title: Text('People')),
                          for (final p in matchedPeople)
                            ListTile(
                              title: Text(p.name),
                              onTap: () => context.push('/people/${p.id}'),
                            ),
                          if (matchedPlaces.isNotEmpty)
                            const ListTile(title: Text('Places')),
                          for (final p in matchedPlaces)
                            ListTile(
                              title: Text(p.name),
                              onTap: () => context.push('/places/${p.id}'),
                            ),
                          const ListTile(title: Text('Expenses')),
                          for (final e in expenses)
                            ListTile(
                              title: Text(e.amount.format()),
                              subtitle: Text(
                                '${e.note ?? e.merchantName ?? ''} ${formatDay(e.timestamp.toLocal())}',
                              ),
                              onTap: () => context.push('/expenses/${e.id}'),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
