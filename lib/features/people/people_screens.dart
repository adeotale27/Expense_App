import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/money.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/enums.dart';
import '../shared/widgets.dart';

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleProvider).valueOrNull ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('People')),
      body: people.isEmpty
          ? EmptyState(
              title: 'No people yet',
              subtitle: 'Track money you owe or that others owe you.',
              action: FilledButton(
                onPressed: () => _addPerson(context, ref),
                child: const Text('Add person'),
              ),
            )
          : ListView.builder(
              itemCount: people.length,
              itemBuilder: (context, i) {
                final p = people[i];
                return FutureBuilder(
                  future: ref.read(ledgerRepoProvider).balanceMinorFor(p.id),
                  builder: (context, snap) {
                    final bal = snap.data ?? 0;
                    final label = bal == 0
                        ? 'Settled'
                        : bal > 0
                            ? 'Owes you ${Money(minorUnits: bal).format()}'
                            : 'You owe ${Money(minorUnits: -bal).format()}';
                    return ListTile(
                      title: Text(p.name),
                      subtitle: Text(label),
                      onTap: () => context.push('/people/${p.id}'),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addPerson(context, ref),
        child: const Icon(Icons.person_add_alt),
      ),
    );
  }
}

Future<void> _addPerson(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Add person'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: 'Name'),
        autofocus: true,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
      ],
    ),
  );
  if (ok == true && controller.text.trim().isNotEmpty) {
    final now = DateTime.now().toUtc();
    await ref.read(personRepoProvider).upsert(
          Person(
            id: newId(),
            userId: ref.read(userIdProvider),
            name: controller.text.trim(),
            createdAt: now,
            updatedAt: now,
            deviceId: ref.read(deviceIdProvider),
          ),
        );
  }
}

class PersonDetailScreen extends ConsumerStatefulWidget {
  const PersonDetailScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends ConsumerState<PersonDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(_entriesProvider(widget.id));
    return FutureBuilder(
      future: ref.read(personRepoProvider).getById(widget.id),
      builder: (context, snap) {
        final person = snap.data;
        if (person == null) {
          return const Scaffold(body: Center(child: Text('Not found')));
        }
        return Scaffold(
          appBar: AppBar(title: Text(person.name)),
          body: entries.when(
            data: (list) {
              final bal = list.fold<int>(0, (p, e) => p + e.signedMinor);
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      bal == 0
                          ? 'Settled'
                          : bal > 0
                              ? '${person.name} owes you ${Money(minorUnits: bal).format()}'
                              : 'You owe ${person.name} ${Money(minorUnits: -bal).format()}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final e in list)
                          ListTile(
                            title: Text('${e.type.name} · ${e.amount.format()}'),
                            subtitle: Text(e.note ?? e.date.toLocal().toString()),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _add(LedgerType.borrowed),
                      child: const Text('They gave me'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _add(LedgerType.lent),
                      child: const Text('I gave them'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _add(LedgerType.repayment),
                      child: const Text('Repay'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _add(LedgerType type) async {
    final amount = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(switch (type) {
          LedgerType.borrowed => 'They gave me',
          LedgerType.lent => 'I gave them',
          _ => 'Repayment',
        }),
        content: TextField(
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    final major = double.tryParse(amount.text) ?? 0;
    if (ok != true || major <= 0) return;
    final now = DateTime.now().toUtc();
    final direction = switch (type) {
      LedgerType.lent => LedgerDirection.owedToUser,
      LedgerType.borrowed => LedgerDirection.owedByUser,
      LedgerType.repayment => LedgerDirection.owedByUser,
      _ => LedgerDirection.owedByUser,
    };
    await ref.read(ledgerRepoProvider).add(
          LedgerEntry(
            id: newId(),
            userId: ref.read(userIdProvider),
            personId: widget.id,
            amount: Money.fromMajor(major),
            direction: direction,
            type: type,
            date: now,
            createdAt: now,
            updatedAt: now,
            deviceId: ref.read(deviceIdProvider),
          ),
        );
    setState(() {});
  }
}

final _entriesProvider =
    StreamProvider.family<List<LedgerEntry>, String>((ref, id) {
  return ref.watch(ledgerRepoProvider).watchForPerson(id);
});
