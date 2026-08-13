import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/utils/dates.dart';
import '../../domain/repositories/repositories.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String q = '';

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
            hintText: 'Search expenses, places, people…',
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: (v) => setState(() => q = v.trim().toLowerCase()),
        ),
      ),
      body: q.isEmpty
          ? const Center(child: Text('Try petrol, Rahul, grocery, ₹500'))
          : FutureBuilder(
              future: ref.read(expenseRepoProvider).list(
                    ExpenseQuery(search: q, limit: 50),
                  ),
              builder: (context, snap) {
                final expenses = snap.data ?? [];
                final matchedPeople =
                    people.where((p) => p.name.toLowerCase().contains(q)).toList();
                final matchedPlaces =
                    places.where((p) => p.name.toLowerCase().contains(q)).toList();
                final matchedCats =
                    cats.where((c) => c.name.toLowerCase().contains(q)).toList();
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
                    if (matchedCats.isNotEmpty)
                      const ListTile(title: Text('Categories')),
                    for (final c in matchedCats)
                      ListTile(title: Text('${c.icon} ${c.name}')),
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
    );
  }
}
