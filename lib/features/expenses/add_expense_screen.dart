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
import '../shared/action_sheet.dart';
import '../shared/selection_grids.dart';
import '../shared/widgets.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({
    super.key,
    this.opportunity,
    this.initialAmountMinor,
    this.placeId,
    this.expense,
  });

  final ExpenseOpportunity? opportunity;
  final int? initialAmountMinor;
  final String? placeId;
  final Expense? expense;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  String raw = '';
  String? categoryId;
  PaymentMethod method = PaymentMethod.upi;
  String? placeId;
  String? personId;
  bool extras = false;
  int catFilter = 0;
  bool saved = false;
  final note = TextEditingController();
  final merchant = TextEditingController();

  bool get isEdit => widget.expense != null;

  double get major {
    if (raw.isEmpty) return 0;
    return double.tryParse(raw) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    if (e != null) {
      raw = e.amount.majorUnits == e.amount.majorUnits.roundToDouble()
          ? '${e.amount.majorUnits.round()}'
          : e.amount.majorUnits.toString();
      categoryId = e.categoryId;
      method = e.paymentMethod;
      placeId = e.placeId;
      note.text = e.note ?? '';
      merchant.text = e.merchantName ?? '';
    } else if (widget.initialAmountMinor != null) {
      raw = '${(widget.initialAmountMinor! / 100).round()}';
    }
    placeId ??= widget.placeId ?? widget.opportunity?.placeId;
  }

  @override
  void dispose() {
    note.dispose();
    merchant.dispose();
    super.dispose();
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
      await ref.read(ledgerRepoProvider).add(
            LedgerEntry(
              id: newId(),
              userId: userId,
              personId: personId!,
              amount: expense.amount,
              direction: LedgerDirection.owedToUser,
              type: LedgerType.lent,
              date: now,
              relatedExpenseId: expense.id,
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
    await Future<void>.delayed(const Duration(milliseconds: 280));
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
    final shown = switch (catFilter) {
      0 => ordered.take(8).toList(),
      1 => ordered
          .where((c) =>
              c.id == habits.frequentCategoryId || c.id == habits.recentCategoryId)
          .toList(),
      _ => ordered,
    };

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit expense' : 'How much?'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 720;
            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 180),
                            style: Theme.of(context).textTheme.displayMedium!.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.2,
                                  color: scheme.onSurface,
                                ),
                            child: Text('₹${raw.isEmpty ? '0' : raw}'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        QuickAmountRow(
                          minors: habits.typicalQuickAmounts,
                          onAmount: (m) => setState(() {
                            raw = '${(m / 100).round()}';
                          }),
                        ),
                        SizedBox(height: compact ? 6 : 10),
                        Expanded(
                          child: AmountKeypad(
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
                        ),
                        SegmentedMini(
                          labels: const ['Recent', 'Frequent', 'All'],
                          index: catFilter,
                          onChanged: (i) => setState(() => catFilter = i),
                        ),
                        const SizedBox(height: 8),
                        CategoryGrid(
                          categories: shown.isEmpty ? ordered : shown,
                          selectedId: categoryId,
                          limit: catFilter == 2 ? 12 : 8,
                          onSelected: (c) => setState(() => categoryId = c.id),
                        ),
                        const SizedBox(height: 10),
                        PaymentMethodGrid(
                          selected: method,
                          preferred: [
                            habits.recentPayment,
                            habits.frequentPayment,
                            PaymentMethod.upi,
                          ],
                          onSelected: (m) => setState(() => method = m),
                        ),
                        TextButton(
                          onPressed: () => setState(() => extras = !extras),
                          child: Text(extras ? 'Hide extras' : 'Where? Who? Note?'),
                        ),
                        if (extras)
                          _Extras(
                            merchant: merchant,
                            note: note,
                            places: places,
                            people: people,
                            placeId: placeId,
                            personId: personId,
                            onPlace: (id) => setState(() => placeId = id),
                            onPerson: (id) => setState(() => personId = id),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: FilledButton(
                    onPressed: major > 0 ? _save : null,
                    child: Text(
                      saved
                          ? 'Saved ₹${raw.isEmpty ? '0' : raw}'
                          : isEdit
                              ? 'Save changes'
                              : 'Save',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Extras extends StatelessWidget {
  const _Extras({
    required this.merchant,
    required this.note,
    required this.places,
    required this.people,
    required this.placeId,
    required this.personId,
    required this.onPlace,
    required this.onPerson,
  });

  final TextEditingController merchant;
  final TextEditingController note;
  final List<Place> places;
  final List<Person> people;
  final String? placeId;
  final String? personId;
  final ValueChanged<String?> onPlace;
  final ValueChanged<String?> onPerson;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (places.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final p in places.take(12))
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(p.name),
                      selected: placeId == p.id,
                      onSelected: (_) => onPlace(placeId == p.id ? null : p.id),
                    ),
                  ),
              ],
            ),
          ),
        if (people.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final p in people.take(12))
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(p.name),
                      selected: personId == p.id,
                      onSelected: (_) => onPerson(personId == p.id ? null : p.id),
                    ),
                  ),
              ],
            ),
          ),
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
    );
  }
}

Future<void> confirmHideCategory(BuildContext context, WidgetRef ref, Category c) async {
  final action = await showActionSheet<String>(
    context,
    title: c.name,
    message: 'This category will stay on past expenses.',
    actions: const [
      SheetAction('Edit', 'edit', icon: Icons.edit_outlined),
      SheetAction('Hide from new expenses', 'hide', icon: Icons.visibility_off_outlined),
    ],
  );
  if (action == 'hide') {
    await ref.read(categoryRepoProvider).upsert(
          c.copyWith(isActive: false, updatedAt: DateTime.now().toUtc()),
        );
  }
}
