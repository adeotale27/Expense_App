import 'package:flutter/material.dart';

import '../../app/haptics.dart';
import '../../app/theme.dart';

Future<T?> showActionSheet<T>(
  BuildContext context, {
  required String title,
  String? message,
  required List<SheetAction<T>> actions,
}) {
  AppHaptics.tap();
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(ctx).textTheme.titleLarge),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(message, style: Theme.of(ctx).textTheme.bodyMedium),
              ],
              const SizedBox(height: 12),
              for (final a in actions)
                ListTile(
                  leading: Icon(a.icon, color: a.destructive ? Theme.of(ctx).colorScheme.error : null),
                  title: Text(
                    a.label,
                    style: a.destructive
                        ? TextStyle(color: Theme.of(ctx).colorScheme.error)
                        : null,
                  ),
                  onTap: () {
                    AppHaptics.tap();
                    Navigator.pop(ctx, a.value);
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

class SheetAction<T> {
  const SheetAction(this.label, this.value, {this.icon, this.destructive = false});
  final String label;
  final T value;
  final IconData? icon;
  final bool destructive;
}

class SuccessBurst extends StatelessWidget {
  const SuccessBurst({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: AppTheme.motion,
      curve: Curves.easeOutBack,
      builder: (context, v, c) => Transform.scale(scale: v, child: c),
      child: child,
    );
  }
}
