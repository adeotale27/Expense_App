import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/haptics.dart';
import '../../app/providers.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/money.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/enums.dart';
import '../shared/widgets.dart';

/// One sheet: name, amount, Given XOR Borrowed, date (defaults to today).
Future<void> showAddFriendSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _AddFriendForm(),
  );
}

class _AddFriendForm extends ConsumerStatefulWidget {
  const _AddFriendForm();

  @override
  ConsumerState<_AddFriendForm> createState() => _AddFriendFormState();
}

enum _LendKind { given, borrowed }

class _AddFriendFormState extends ConsumerState<_AddFriendForm> {
  final name = TextEditingController();
  final amount = TextEditingController();
  _LendKind? kind = _LendKind.given;
  DateTime date = DateTime.now();
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(date.year - 5),
      lastDate: DateTime(date.year + 1),
    );
    if (picked != null) setState(() => date = picked);
  }

  Future<void> _save() async {
    final who = name.text.trim();
    final major = double.tryParse(amount.text.trim()) ?? 0;
    if (who.isEmpty || major <= 0 || kind == null || saving) return;
    setState(() => saving = true);
    AppHaptics.confirm();
    final now = DateTime.now().toUtc();
    final when = DateTime(date.year, date.month, date.day, now.hour, now.minute).toUtc();
    final person = Person(
      id: newId(),
      userId: ref.read(userIdProvider),
      name: who,
      createdAt: now,
      updatedAt: now,
      deviceId: ref.read(deviceIdProvider),
    );
    await ref.read(personRepoProvider).upsert(person);
    final given = kind == _LendKind.given;
    await ref.read(ledgerRepoProvider).add(
          LedgerEntry(
            id: newId(),
            userId: ref.read(userIdProvider),
            personId: person.id,
            amount: Money.fromMajor(major),
            direction: given ? LedgerDirection.owedToUser : LedgerDirection.owedByUser,
            type: given ? LedgerType.lent : LedgerType.borrowed,
            date: when,
            note: given ? 'Given' : 'Borrowed',
            createdAt: now,
            updatedAt: now,
            deviceId: ref.read(deviceIdProvider),
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add friend', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Name, amount, and whether you gave or borrowed. One direction only.'),
            const SizedBox(height: 16),
            TextField(
              controller: name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            AmountField(
              controller: amount,
              large: false,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Text('Direction', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _KindCard(
                    title: 'Given',
                    subtitle: 'They owe you',
                    selected: kind == _LendKind.given,
                    color: scheme.primary,
                    onTap: () => setState(() => kind = _LendKind.given),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KindCard(
                    title: 'Borrowed',
                    subtitle: 'You owe them',
                    selected: kind == _LendKind.borrowed,
                    color: scheme.tertiary,
                    onTap: () => setState(() => kind = _LendKind.borrowed),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Date'),
              subtitle: Text(DateFormat('EEE, d MMM y').format(date)),
              trailing: TextButton(onPressed: _pickDate, child: const Text('Change')),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _save,
              child: Text(saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _KindCard extends StatelessWidget {
  const _KindCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.16) : Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? color : Theme.of(context).colorScheme.outlineVariant, width: selected ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: color),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
