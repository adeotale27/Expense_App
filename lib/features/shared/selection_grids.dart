import 'package:flutter/material.dart';

import '../../domain/entities/entities.dart';
import '../../domain/enums/enums.dart';
import 'selection_tile.dart';

class PaymentMethodGrid extends StatelessWidget {
  const PaymentMethodGrid({
    super.key,
    required this.selected,
    required this.onSelected,
    this.preferred = const [],
  });

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onSelected;
  final List<PaymentMethod> preferred;

  static const visible = [
    PaymentMethod.upi,
    PaymentMethod.cash,
    PaymentMethod.creditCard,
    PaymentMethod.debitCard,
    PaymentMethod.bankTransfer,
    PaymentMethod.wallet,
  ];

  IconData _icon(PaymentMethod m) => switch (m) {
        PaymentMethod.upi => Icons.qr_code_2_rounded,
        PaymentMethod.cash => Icons.payments_outlined,
        PaymentMethod.creditCard => Icons.credit_card,
        PaymentMethod.debitCard => Icons.credit_card_outlined,
        PaymentMethod.bankTransfer => Icons.account_balance_outlined,
        PaymentMethod.wallet => Icons.account_balance_wallet_outlined,
        PaymentMethod.other => Icons.more_horiz,
        PaymentMethod.notSpecified => Icons.more_horiz,
      };

  @override
  Widget build(BuildContext context) {
    final ordered = [
      ...preferred.where(visible.contains),
      ...visible.where((m) => !preferred.contains(m)),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final m in ordered)
          SizedBox(
            width: 96,
            child: SelectionTile(
              label: m.label,
              selected: selected == m,
              icon: _icon(m),
              compact: true,
              onTap: () => onSelected(m),
              semanticLabel: 'Payment method ${m.label}',
            ),
          ),
      ],
    );
  }
}

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    this.limit,
    this.onLongPress,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<Category> onSelected;
  final int? limit;
  final ValueChanged<Category>? onLongPress;

  @override
  Widget build(BuildContext context) {
    final items = limit == null ? categories : categories.take(limit!).toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in items)
          SizedBox(
            width: 88,
            child: GestureDetector(
              onLongPress: onLongPress == null ? null : () => onLongPress!(c),
              child: SelectionTile.emoji(
                label: c.name,
                emoji: c.icon,
                selected: selectedId == c.id,
                color: Color(c.accentColor),
                compact: true,
                onTap: () => onSelected(c),
                semanticLabel: 'Category ${c.name}',
              ),
            ),
          ),
      ],
    );
  }
}

class QuickAmountRow extends StatelessWidget {
  const QuickAmountRow({
    super.key,
    required this.onAmount,
    this.minors = const [10000, 20000, 50000],
    this.onCustom,
  });

  final ValueChanged<int> onAmount;
  final List<int> minors;
  final VoidCallback? onCustom;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final m in minors.take(3)) ...[
          Expanded(
            child: SelectionTile(
              label: '₹${(m / 100).round()}',
              selected: false,
              compact: true,
              onTap: () => onAmount(m),
              semanticLabel: 'Quick add ${(m / 100).round()} rupees',
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (onCustom != null)
          Expanded(
            child: SelectionTile(
              label: 'Custom',
              selected: false,
              compact: true,
              onTap: onCustom!,
            ),
          ),
      ],
    );
  }
}

class SegmentedMini extends StatelessWidget {
  const SegmentedMini({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        for (var i = 0; i < labels.length; i++)
          ChoiceChip(
            label: Text(labels[i]),
            selected: index == i,
            onSelected: (_) => onChanged(i),
          ),
      ],
    );
  }
}
