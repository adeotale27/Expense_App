import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/haptics.dart';
import '../../app/quick_spend.dart';
import '../shared/widgets.dart';

class WidgetComposeScreen extends ConsumerStatefulWidget {
  const WidgetComposeScreen({super.key});

  @override
  ConsumerState<WidgetComposeScreen> createState() => _WidgetComposeScreenState();
}

class _WidgetComposeScreenState extends ConsumerState<WidgetComposeScreen> {
  final amount = TextEditingController();
  final other = TextEditingController();
  final amountFocus = FocusNode();
  final otherFocus = FocusNode();
  String category = 'Food';
  bool saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) amountFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    amount.dispose();
    other.dispose();
    amountFocus.dispose();
    otherFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final major = double.tryParse(amount.text.trim()) ?? 0;
    if (major <= 0) {
      amountFocus.requestFocus();
      return;
    }
    setState(() => saving = true);
    AppHaptics.confirm();
    final what = category == 'Other'
        ? (other.text.trim().isEmpty ? 'Other' : other.text.trim())
        : category;
    await recordNamedSpend(
      ref,
      amountMinor: (major * 100).round(),
      what: what,
    );
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add spend')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            AmountField(
              controller: amount,
              focusNode: amountFocus,
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Text('Category', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final name in const ['Food', 'Fuel', 'Other']) ...[
                  Expanded(
                    child: ChoiceChip(
                      label: Text(name),
                      selected: category == name,
                      onSelected: (_) {
                        setState(() => category = name);
                        if (name == 'Other') {
                          otherFocus.requestFocus();
                        } else {
                          amountFocus.requestFocus();
                        }
                      },
                    ),
                  ),
                  if (name != 'Other') const SizedBox(width: 8),
                ],
              ],
            ),
            if (category == 'Other') ...[
              const SizedBox(height: 12),
              TextField(
                controller: other,
                focusNode: otherFocus,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Type what it was'),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: saving ? null : _save,
              child: Text(saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
