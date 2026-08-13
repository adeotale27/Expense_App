import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/enums.dart';

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
        final cat = cats.where((c) => c.id == e.categoryId).firstOrNull;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Expense'),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy),
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
                onPressed: () async {
                  await ref.read(expenseRepoProvider).softDelete(e.id, DateTime.now().toUtc());
                  if (context.mounted) context.pop();
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(e.amount.format(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
              const SizedBox(height: 8),
              Text('${cat?.icon ?? ''} ${cat?.name ?? ''}'.trim(),
                  style: Theme.of(context).textTheme.titleLarge),
              if (e.merchantName != null) Text(e.merchantName!),
              const SizedBox(height: 16),
              Text(formatDay(e.timestamp.toLocal())),
              Text(formatTime(e.timestamp.toLocal())),
              const SizedBox(height: 16),
              Text('Payment: ${e.paymentMethod.label}'),
              if (e.note != null) ...[
                const SizedBox(height: 12),
                Text('Note: ${e.note}'),
              ],
            ],
          ),
        );
      },
    );
  }
}
