import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/haptics.dart';
import '../../app/providers.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/money.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/enums.dart';
import '../habits/habit_engine.dart';
import '../shared/selection_grids.dart';
import '../shared/widgets.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({
    super.key,
    this.opportunity,
    this.initialAmountMinor,
    this.initialWhat,
    this.placeId,
    this.expense,
  });

  final ExpenseOpportunity? opportunity;
  final int? initialAmountMinor;
  final String? initialWhat;
  final String? placeId;
  final Expense? expense;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  late final TextEditingController amount;
  final note = TextEditingController();
  final merchant = TextEditingController();
  final amountFocus = FocusNode();
  String? categoryId;
  PaymentMethod method = PaymentMethod.upi;
  String? placeId;
  String? personId;
  bool splitEqually = false;
  int step = 0;
  bool saved = false;

  bool get isEdit => widget.expense != null;

  double get major {
    final raw = amount.text.trim();
    if (raw.isEmpty) return 0;
    return double.tryParse(raw) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    amount = TextEditingController();
    final e = widget.expense;
    if (e != null) {
      amount.text = e.amount.majorUnits == e.amount.majorUnits.roundToDouble()
          ? '${e.amount.majorUnits.round()}'
          : e.amount.majorUnits.toString();
      categoryId = e.categoryId;
      method = e.paymentMethod;
      placeId = e.placeId;
      note.text = e.note ?? '';
      merchant.text = e.merchantName ?? '';
      step = 1;
    } else if (widget.initialAmountMinor != null) {
      amount.text = '${(widget.initialAmountMinor! / 100).round()}';
    }
    if (widget.initialWhat != null && widget.initialWhat!.trim().isNotEmpty) {
      note.text = widget.initialWhat!.trim();
    }
    placeId ??= widget.placeId ?? widget.opportunity?.placeId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && step == 0) amountFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    merchant.dispose();
    amountFocus.dispose();
    super.dispose();
  }

  void _digit(String d) {
    setState(() {
      if (d == '.' && amount.text.contains('.')) return;
      amount.text += d;
      amount.selection = TextSelection.collapsed(offset: amount.text.length);
    });
  }

  void _back() {
    if (amount.text.isEmpty) return;
    setState(() {
      amount.text = amount.text.substring(0, amount.text.length - 1);
      amount.selection = TextSelection.collapsed(offset: amount.text.length);
    });
  }

  Future<void> _save() async {
    if (major <= 0) return;
    final cats = ref.read(categoriesProvider).valueOrNull ?? [];
    final allCats = await ref.read(categoryRepoProvider).all();
    var catId = categoryId;
    catId ??= allCats.where((c) => c.name == 'Other').firstOrNull?.id ??
        (cats.isNotEmpty ? cats.first.id : null);
    if (catId == null) return;
    AppHaptics.confirm();
    final userId = ref.read(userIdProvider);
    final deviceId = ref.read(deviceIdProvider);
    final now = DateTime.now().toUtc();
    final opp = widget.opportunity;
    final existing = widget.expense;
    final expense = Expense(
      id: existing?.id ?? newId(),
      userId: userId,
      amount: Money.fromMajor(major),
      categoryId: catId,
      merchantName: merchant.text.trim().isEmpty ? null : merchant.text.trim(),
      placeId: placeId ?? opp?.placeId,
      paymentMethod: method,
      note: note.text.trim().isEmpty ? null : note.text.trim(),
      timestamp: existing?.timestamp ?? now,
      source: opp == null ? ExpenseSource.manual : ExpenseSource.locationPrompt,
      opportunityId: opp?.id,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      deviceId: deviceId,
    );
    await ref.read(expenseRepoProvider).upsert(expense);
    if (personId != null && existing == null) {
      final share = splitEqually ? major / 2 : major;
      await ref.read(ledgerRepoProvider).add(
            LedgerEntry(
              id: newId(),
              userId: userId,
              personId: personId!,
              amount: Money.fromMajor(share),
              direction: LedgerDirection.owedToUser,
              type: LedgerType.lent,
              date: now,
              relatedExpenseId: expense.id,
              note: splitEqually ? 'Split equally' : 'I paid',
              createdAt: now,
              updatedAt: now,
              deviceId: deviceId,
            ),
          );
    }
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
                totalSpendMinor: place.totalSpendMinor + expense.amount.minorUnits,
                lastVisitedAt: now,
                updatedAt: now,
              ),
            );
      }
    }
    final settings = await ref.read(settingsRepoProvider).get(userId);
    await ref.read(settingsRepoProvider).save(
          settings.copyWith(
            lastCategoryId: catId,
            lastPaymentMethod: method,
          ),
        );
    try {
      await ref.read(syncEngineProvider).syncAll();
    } catch (_) {}
    if (!mounted) return;
    setState(() => saved = true);
    await Future<void>.delayed(const Duration(milliseconds: 240));
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final expenses = ref.watch(recentExpensesProvider).valueOrNull ?? [];
    final places = ref.watch(placesProvider).valueOrNull ?? [];
    final people = ref.watch(peopleProvider).valueOrNull ?? [];
    final settings = ref.watch(settingsProvider).valueOrNull;
    final opp = widget.opportunity;
    if (opp?.suggestedCategoryId != null && categoryId == null) {
      categoryId = opp!.suggestedCategoryId;
    }
    if (opp?.suggestedMerchantName != null && merchant.text.isEmpty) {
      merchant.text = opp!.suggestedMerchantName!;
    }
    if (widget.initialWhat != null && categoryId == null) {
      final needle = widget.initialWhat!.trim().toLowerCase();
      categoryId = cats.where((c) => c.name.toLowerCase() == needle).firstOrNull?.id ??
          cats.where((c) => c.name.toLowerCase().contains(needle)).firstOrNull?.id;
    }
    categoryId ??= settings?.lastCategoryId;
    if (widget.expense == null && method == PaymentMethod.upi) {
      method = settings?.lastPaymentMethod ?? method;
    }
    final habits = HabitEngine().learn(
      expenses: expenses,
      places: places,
      visits: const [],
      settings: settings,
    );
    final ordered = HabitEngine().orderCategories(cats, habits);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit spend' : (step == 0 ? 'How much?' : 'What was it?')),
        leading: step == 1 && !isEdit
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => step = 0),
              )
            : null,
      ),
      body: SafeArea(
        child: step == 0 ? _amountStep(habits) : _detailsStep(ordered, habits, places, people),
      ),
    );
  }

  Widget _amountStep(SpendingHabits habits) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        children: [
          AmountField(
            controller: amount,
            focusNode: amountFocus,
            autofocus: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          QuickAmountRow(
            minors: habits.typicalQuickAmounts,
            onAmount: (m) => setState(() {
              amount.text = '${(m / 100).round()}';
              amount.selection = TextSelection.collapsed(offset: amount.text.length);
            }),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AmountKeypad(onDigit: _digit, onBack: _back),
          ),
          FilledButton(
            onPressed: major > 0 ? () => setState(() => step = 1) : null,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _detailsStep(
    List<Category> ordered,
    SpendingHabits habits,
    List<Place> places,
    List<Person> people,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => step = 0),
            child: AmountField(
              controller: amount,
              large: false,
              onChanged: (_) => setState(() {}),
            ),
          ),
          Text(
            'Tap or type to edit the amount',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                Text('Category', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                CategoryGrid(
                  categories: ordered,
                  selectedId: categoryId,
                  limit: 10,
                  onSelected: (c) => setState(() => categoryId = c.id),
                ),
                const SizedBox(height: 16),
                Text('Paid with', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                PaymentMethodGrid(
                  selected: method,
                  preferred: [
                    habits.recentPayment,
                    habits.frequentPayment,
                    PaymentMethod.upi,
                  ],
                  onSelected: (m) => setState(() => method = m),
                ),
                if (places.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Where', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final p in places.take(10))
                        ChoiceChip(
                          label: Text(p.name),
                          selected: placeId == p.id,
                          onSelected: (_) =>
                              setState(() => placeId = placeId == p.id ? null : p.id),
                        ),
                    ],
                  ),
                ],
                if (people.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Split with a friend', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final p in people.take(10))
                        ChoiceChip(
                          label: Text(p.name),
                          selected: personId == p.id,
                          onSelected: (_) =>
                              setState(() => personId = personId == p.id ? null : p.id),
                        ),
                    ],
                  ),
                  if (personId != null)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Split equally'),
                      subtitle: Text(
                        splitEqually
                            ? 'They owe ${Money.fromMajor(major / 2).format()}'
                            : 'They owe the full ${Money.fromMajor(major).format()}',
                      ),
                      value: splitEqually,
                      onChanged: (v) => setState(() => splitEqually = v),
                    ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: merchant,
                  decoration: const InputDecoration(labelText: 'Merchant (optional)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: note,
                  decoration: const InputDecoration(labelText: 'Note (optional)'),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: major > 0 ? _save : null,
            child: Text(saved ? 'Saved' : isEdit ? 'Save changes' : 'Record spend'),
          ),
        ],
      ),
    );
  }
}
