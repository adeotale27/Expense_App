import 'package:flutter/material.dart';

import '../../app/haptics.dart';
import '../../app/theme.dart';

class SelectionTile extends StatelessWidget {
  const SelectionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.emoji,
    this.color,
    this.compact = false,
    this.semanticLabel,
  });

  const SelectionTile.emoji({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.emoji,
    this.color,
    this.compact = false,
    this.semanticLabel,
  }) : icon = null;

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final String? emoji;
  final Color? color;
  final bool compact;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel ?? label,
      child: AnimatedScale(
        scale: selected ? 1.04 : 1,
        duration: AppTheme.motion,
        curve: Curves.easeOutCubic,
        child: Material(
          color: selected
              ? accent.withValues(alpha: 0.16)
              : scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              AppHaptics.tap();
              onTap();
            },
            child: AnimatedContainer(
              duration: AppTheme.motion,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 12,
                vertical: compact ? 8 : 12,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? accent : scheme.outlineVariant,
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null)
                    Icon(icon, color: selected ? accent : scheme.onSurfaceVariant),
                  if (emoji != null)
                    Text(emoji!, style: TextStyle(fontSize: compact ? 18 : 22)),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                          color: selected ? accent : scheme.onSurface,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
