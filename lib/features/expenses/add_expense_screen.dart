import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/money.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/enums.dart';
import '../shared/widgets.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, this.opportunity});

  final ExpenseOpportunity? opportunity;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  String raw = '';
  String? categoryId;
  PaymentMethod method = PaymentMethod.notSpecified;
  final note = TextEditingController();
  final merchant = TextEditingController();

  double get major {
    if (raw.isEmpty) return 0;
    return double.tryParse(raw) ?? 0;
  }

  Future<void> _save() async {
    if (major <= 0 || categoryId == null) return;
    final userId = ref.read(userIdProvider);
    final deviceId = ref.read(deviceIdProvider);
    final now = DateTime.now().toUtc();
    final opp = widget.opportunity;
    final expense = Expense(
      id: newId(),
      userId: userId,
      amount: Money.fromMajor(major),
      categoryId: categoryId!,
      merchantName: merchant.text.trim().isEmpty ? null : merchant.text.trim(),
      placeId: opp?.placeId,
      paymentMethod: method,
      note: note.text.trim().isEmpty ? null : note.text.trim(),
      timestamp: now,
      source: opp == null ? ExpenseSource.manual : ExpenseSource.locationPrompt,
      opportunityId: opp?.id,
      createdAt: now,
      updatedAt: now,
      deviceId: deviceId,
    );
    await ref.read(expenseRepoProvider).upsert(expense);
    if (opp != null) {
      await ref.read(opportunityRepoProvider).upsert(
            opp.copyWith(
              status: OpportunityStatus.expenseAdded,
              updatedAt: now,
            ),
          );
    }
    if (expense.placeId != null) {
      final place = await ref.read(placeRepoProvider).getById(expense.placeId!);
      if (place != null) {
        await ref.read(placeRepoProvider).upsert(
              place.copyWith(
                visitCount: place.visitCount + 1,
                totalSpendMinor: place.totalSpendMinor + expense.amount.minorUnits,
                lastVisitedAt: now,
                updatedAt: now,
              ),
            );
      }
    }
    try {
      await ref.read(syncEngineProvider).syncAll();
    } catch (_) {}
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final opp = widget.opportunity;
    if (opp?.suggestedCategoryId != null && categoryId == null) {
      categoryId = opp!.suggestedCategoryId;
    }
    if (opp?.suggestedMerchantName != null && merchant.text.isEmpty) {
      merchant.text = opp!.suggestedMerchantName!;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('How much?')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Text(
              '₹${raw.isEmpty ? '0' : raw}',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          AmountKeypad(
            onDigit: (d) {
              setState(() {
                if (d == '.' && raw.contains('.')) return;
                raw += d;
              });
            },
            onBack: () {
              if (raw.isEmpty) return;
              setState(() => raw = raw.substring(0, raw.length - 1));
            },
          ),
          const SizedBox(height: 8),
          Text('Category', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in cats.take(8))
                ChoiceChip(
                  label: Text('${c.icon} ${c.name}'),
                  selected: categoryId == c.id,
                  onSelected: (_) => setState(() => categoryId = c.id),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: merchant,
            decoration: const InputDecoration(labelText: 'Merchant (optional)'),
          ),
          const SizedBox(height: 8),
            DropdownButtonFormField<PaymentMethod>(
            value: method,
            items: [
              for (final m in PaymentMethod.values)
                DropdownMenuItem(value: m, child: Text(m.label)),
            ],
            onChanged: (v) => setState(() => method = v ?? method),
            decoration: const InputDecoration(labelText: 'Payment method'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: note,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: major > 0 && categoryId != null ? _save : null,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
