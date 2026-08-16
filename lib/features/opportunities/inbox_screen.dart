import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/dates.dart';
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
      appBar: AppBar(title: const Text('Potential spends')),
      body: items.isEmpty
          ? const EmptyState(
              title: 'All caught up',
              subtitle: 'Visit prompts appear here. SpendPing never creates an expense until you confirm.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final o = items[i];
                final place = places[o.placeId];
                return QuietCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📍 ${place?.name ?? o.suggestedMerchantName ?? 'Unknown place'}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${formatDay(o.detectedAt.toLocal())} · ${formatTime(o.detectedAt.toLocal())}',
                      ),
                      const SizedBox(height: 8),
                      const Text('Did you spend anything?'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AddExpenseScreen(opportunity: o),
                                  ),
                                );
                              },
                              child: const Text('Record'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await ref.read(opportunityRepoProvider).upsert(
                                      o.copyWith(
                                        status: OpportunityStatus.nothingSpent,
                                        updatedAt: DateTime.now().toUtc(),
                                      ),
                                    );
                              },
                              child: const Text('Dismiss'),
                            ),
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
