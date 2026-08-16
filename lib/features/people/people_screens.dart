import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/haptics.dart';
import '../../app/providers.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/money.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/enums.dart';
import '../shared/action_sheet.dart';
import '../shared/widgets.dart';

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleProvider).valueOrNull ?? [];
    final entries = ref.watch(ledgerEntriesProvider).valueOrNull ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            tooltip: 'Add friend',
            onPressed: () => _addPerson(context, ref),
            icon: const Icon(Icons.person_add_alt),
          ),
        ],
      ),
      body: people.isEmpty
          ? EmptyState(
              title: 'Split like Splitwise',
              subtitle: 'Add a friend, log who paid, then settle when you actually transfer money.',
              action: FilledButton(
                onPressed: () => _addPerson(context, ref),
                child: const Text('Add friend'),
              ),
            )
          : Builder(
              builder: (context) {
                final net = entries.fold<int>(0, (p, e) => p + e.signedMinor);
                final headline = net == 0
                    ? 'All settled'
                    : net > 0
                        ? 'Overall, you are owed ${Money(minorUnits: net).format()}'
                        : 'Overall, you owe ${Money(minorUnits: -net).format()}';
                int balanceFor(String id) => entries
                    .where((e) => e.personId == id)
                    .fold<int>(0, (p, e) => p + e.signedMinor);
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 108),
                  itemCount: people.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return GradientHero(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('BALANCES', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.1)),
                            const SizedBox(height: 8),
                            Text(headline, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                            const Text('Ledger only — money still moves outside the app.'),
                          ],
                        ),
                      );
                    }
                    final p = people[i - 1];
                    final bal = balanceFor(p.id);
                    final color = bal == 0
                        ? Theme.of(context).colorScheme.onSurface
                        : bal > 0
                            ? const Color(0xFF0FBE8F)
                            : const Color(0xFFFF6B57);
                    final label = bal == 0
                        ? 'Settled up'
                        : bal > 0
                            ? 'owes you ${Money(minorUnits: bal).format()}'
                            : 'you owe ${Money(minorUnits: -bal).format()}';
                    return QuietCard(
                      onTap: () => context.push('/people/${p.id}'),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: color.withValues(alpha: 0.16),
                            child: Text(
                              p.name.isEmpty ? '?' : p.name[0].toUpperCase(),
                              style: TextStyle(fontWeight: FontWeight.w800, color: color),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                                Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

Future<void> _addPerson(BuildContext context, WidgetRef ref) async {
  final name = TextEditingController();
  final created = await showModalBottomSheet<Person>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.viewInsetsOf(ctx).bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Text("Who's this?", style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Then you can log I paid / they paid / split equally — same idea as Splitwise, on this device.'),
            const SizedBox(height: 12),
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) return;
                final now = DateTime.now().toUtc();
                final person = Person(
                  id: newId(),
                  userId: ref.read(userIdProvider),
                  name: name.text.trim(),
                  createdAt: now,
                  updatedAt: now,
                  deviceId: ref.read(deviceIdProvider),
                );
                await ref.read(personRepoProvider).upsert(person);
                if (ctx.mounted) Navigator.pop(ctx, person);
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    },
  );
  if (created == null || !context.mounted) return;
  await _firstTransaction(context, ref, created);
}

Future<void> _firstTransaction(BuildContext context, WidgetRef ref, Person person) async {
  final kind = await showModalBottomSheet<LedgerType>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What happened?', style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, LedgerType.lent),
                child: const Text('I paid for them'),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(ctx, LedgerType.borrowed),
                child: const Text('They paid for me'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx, LedgerType.adjustment),
                child: const Text('Split equally'),
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Skip for now')),
            ],
          ),
        ),
      );
    },
  );
  if (kind == null || !context.mounted) return;
  await _amountSheet(context, ref, person.id, kind);
}

Future<void> _amountSheet(
  BuildContext context,
  WidgetRef ref,
  String personId,
  LedgerType type, {
  int? suggestedMinor,
}) async {
  final amount = TextEditingController(
    text: suggestedMinor == null || suggestedMinor <= 0
        ? ''
        : '${(suggestedMinor / 100).round()}',
  );
  final title = switch (type) {
    LedgerType.lent => 'I paid',
    LedgerType.borrowed => 'They paid',
    LedgerType.adjustment => 'Split equally — bill total',
    LedgerType.settlement => 'Settle up',
    LedgerType.repayment => 'Repayment',
  };
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.viewInsetsOf(ctx).bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            if (type == LedgerType.settlement)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Mark the amount you actually transferred outside SpendPing.'),
              ),
            AmountField(controller: amount, large: false, autofocus: true),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      );
    },
  );
  final major = double.tryParse(amount.text) ?? 0;
  if (ok != true || major <= 0) return;
  final now = DateTime.now().toUtc();
  var entryType = type;
  var entryMajor = major;
  String? note;
  if (type == LedgerType.adjustment) {
    entryType = LedgerType.lent;
    entryMajor = major / 2;
    note = 'Split equally of ${Money.fromMajor(major).format()}';
  }
  LedgerDirection direction;
  if (type == LedgerType.settlement) {
    final current = await ref.read(ledgerRepoProvider).balanceMinorFor(personId);
    direction = current >= 0 ? LedgerDirection.owedToUser : LedgerDirection.owedByUser;
    note = 'Settled up';
  } else {
    direction = switch (entryType) {
      LedgerType.lent => LedgerDirection.owedToUser,
      LedgerType.borrowed => LedgerDirection.owedByUser,
      LedgerType.adjustment => LedgerDirection.owedToUser,
      LedgerType.repayment => LedgerDirection.owedByUser,
      LedgerType.settlement => LedgerDirection.owedToUser,
    };
  }
  await ref.read(ledgerRepoProvider).add(
        LedgerEntry(
          id: newId(),
          userId: ref.read(userIdProvider),
          personId: personId,
          amount: Money.fromMajor(entryMajor),
          direction: direction,
          type: entryType,
          date: now,
          note: note,
          createdAt: now,
          updatedAt: now,
          deviceId: ref.read(deviceIdProvider),
        ),
      );
}

class PersonDetailScreen extends ConsumerStatefulWidget {
  const PersonDetailScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends ConsumerState<PersonDetailScreen> {
  String filter = 'all';

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
          appBar: AppBar(
            title: Text(person.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () => _personActions(person),
              ),
            ],
          ),
          body: entries.when(
            data: (list) {
              final lent = list
                  .where((e) => e.signedMinor > 0)
                  .fold<int>(0, (p, e) => p + e.signedMinor);
              final borrowed = list
                  .where((e) => e.signedMinor < 0)
                  .fold<int>(0, (p, e) => p + e.signedMinor.abs());
              final bal = lent - borrowed;
              final shown = switch (filter) {
                'they' => list.where((e) => e.signedMinor > 0).toList(),
                'you' => list.where((e) => e.signedMinor < 0).toList(),
                _ => list,
              };
              return SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: GradientHero(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bal == 0
                                  ? 'Settled up'
                                  : bal > 0
                                      ? 'owes you ${Money(minorUnits: bal).format()}'
                                      : 'you owe ${Money(minorUnits: -bal).format()}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                            ),
                            const Text('Transfers happen in UPI / cash. This is just the IOU list.'),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          _stat('They owe', lent, () => setState(() => filter = 'they')),
                          const SizedBox(width: 8),
                          _stat('You owe', borrowed, () => setState(() => filter = 'you')),
                          const SizedBox(width: 8),
                          _stat('Net', bal, () => setState(() => filter = 'all'), signed: true),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          for (final e in shown)
                            ListTile(
                              title: Text('${e.type.name} · ${e.amount.format()}'),
                              subtitle: Text(e.note ?? e.date.toLocal().toString().split('.').first),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => _amountSheet(context, ref, widget.id, LedgerType.lent),
                                  child: const Text('I paid'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton.tonal(
                                  onPressed: () => _amountSheet(context, ref, widget.id, LedgerType.borrowed),
                                  child: const Text('They paid'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _amountSheet(context, ref, widget.id, LedgerType.adjustment),
                                  child: const Text('Split equally'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _amountSheet(
                                    context,
                                    ref,
                                    widget.id,
                                    LedgerType.settlement,
                                    suggestedMinor: bal.abs(),
                                  ),
                                  child: const Text('Settle up'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
          ),
        );
      },
    );
  }

  Widget _stat(String label, int minor, VoidCallback onTap, {bool signed = false}) {
    final text = signed
        ? '${minor >= 0 ? '+' : '-'}${Money(minorUnits: minor.abs()).format()}'
        : Money(minorUnits: minor).format();
    return Expanded(
      child: QuietCard(
        onTap: () {
          AppHaptics.tap();
          onTap();
        },
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Future<void> _personActions(Person person) async {
    final action = await showActionSheet<String>(
      context,
      title: person.name,
      actions: const [
        SheetAction('Edit', 'edit', icon: Icons.edit_outlined),
        SheetAction('Archive', 'archive', icon: Icons.archive_outlined),
        SheetAction('Delete', 'delete', icon: Icons.delete_outline, destructive: true),
      ],
    );
    if (action == 'edit') {
      if (!mounted) return;
      final name = TextEditingController(text: person.name);
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Edit person'),
          content: TextField(controller: name),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      );
      if (ok == true && name.text.trim().isNotEmpty) {
        await ref.read(personRepoProvider).upsert(
              person.copyWith(name: name.text.trim(), updatedAt: DateTime.now().toUtc()),
            );
        setState(() {});
      }
    }
    if (action == 'archive') {
      await ref.read(personRepoProvider).upsert(
            person.copyWith(archived: true, updatedAt: DateTime.now().toUtc()),
          );
      if (mounted) context.pop();
    }
    if (action == 'delete') {
      await ref.read(personRepoProvider).softDelete(person.id, DateTime.now().toUtc());
      if (mounted) context.pop();
    }
  }
}

final _entriesProvider =
    StreamProvider.family<List<LedgerEntry>, String>((ref, id) {
  return ref.watch(ledgerRepoProvider).watchForPerson(id);
});
