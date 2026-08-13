import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/enums/enums.dart';
import '../expenses/add_expense_screen.dart';
import '../shared/widgets.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(pendingOpportunitiesProvider).valueOrNull ?? [];
    final places = {for (final p in ref.watch(placesProvider).valueOrNull ?? []) p.id: p};
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses to Review')),
      body: items.isEmpty
          ? const EmptyState(
              title: 'All caught up',
              subtitle: 'Possible expenses from visits will show up here, even if you ignore a notification.',
            )
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final o = items[i];
                final place = places[o.placeId];
                return QuietCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place?.name ?? o.suggestedMerchantName ?? 'Unknown place',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Did you spend anything?  ·  confidence ${o.confidenceScore}',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          FilledButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AddExpenseScreen(opportunity: o),
                                ),
                              );
                            },
                            child: const Text('Add'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () async {
                              await ref.read(opportunityRepoProvider).upsert(
                                    o.copyWith(
                                      status: OpportunityStatus.nothingSpent,
                                      updatedAt: DateTime.now().toUtc(),
                                    ),
                                  );
                            },
                            child: const Text('Nothing'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () async {
                              await ref.read(opportunityRepoProvider).upsert(
                                    o.copyWith(
                                      status: OpportunityStatus.dismissed,
                                      updatedAt: DateTime.now().toUtc(),
                                    ),
                                  );
                            },
                            child: const Text('Later'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
