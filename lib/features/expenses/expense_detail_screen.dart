import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/enums.dart';
import 'add_expense_screen.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(expenseRepoProvider).getById(id),
      builder: (context, snap) {
        final e = snap.data;
        if (e == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
        final allCats = ref.watch(allCategoriesProvider).valueOrNull ?? cats;
        final cat = allCats.where((c) => c.id == e.categoryId).firstOrNull ??
            cats.where((c) => c.id == e.categoryId).firstOrNull;
        final places = ref.watch(placesProvider).valueOrNull ?? [];
        final place = places.where((p) => p.id == e.placeId).firstOrNull;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Expense'),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Duplicate',
                onPressed: () async {
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
                          deviceId: ref.read(deviceIdProvider),
                        ),
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Duplicated')),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
                onPressed: () async {
                  await ref.read(expenseRepoProvider).softDelete(e.id, DateTime.now().toUtc());
                  if (context.mounted) context.pop();
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.amount.format(),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${cat?.icon ?? ''} ${cat?.name ?? ''}'.trim(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text('${e.paymentMethod.label}${place == null ? '' : ' · ${place.name}'}'),
                  Text('${formatDay(e.timestamp.toLocal())} · ${formatTime(e.timestamp.toLocal())}'),
                  if (e.note != null) ...[
                    const SizedBox(height: 12),
                    Text('Note: ${e.note}'),
                  ],
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddExpenseScreen(expense: e),
                        ),
                      );
                    },
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
