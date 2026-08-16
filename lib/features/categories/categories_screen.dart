import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';
import '../shared/action_sheet.dart';
import '../shared/selection_grids.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(allCategoriesProvider).valueOrNull ?? [];
    final active = cats.where((c) => c.isActive).toList();
    final hidden = cats.where((c) => !c.isActive).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Manage categories')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            Text('Active', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            CategoryGrid(
              categories: active,
              selectedId: null,
              onSelected: (c) => _edit(context, ref, c),
              onLongPress: (c) => _long(context, ref, c),
            ),
            if (hidden.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Hidden / Removed', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Hidden categories stay on past expenses and can be restored.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              CategoryGrid(
                categories: hidden,
                selectedId: null,
                onSelected: (c) => _restore(ref, c),
                onLongPress: (c) => _long(context, ref, c),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref, null, sort: cats.length),
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
    );
  }

  Future<void> _restore(WidgetRef ref, Category c) async {
    await ref.read(categoryRepoProvider).upsert(
          c.copyWith(isActive: true, updatedAt: DateTime.now().toUtc()),
        );
  }

  Future<void> _long(BuildContext context, WidgetRef ref, Category c) async {
    final action = await showActionSheet<String>(
      context,
      title: c.name,
      message: c.isActive
          ? "Remove from categories? This category won't appear for new expenses."
          : 'Restore this category for new expenses?',
      actions: [
        const SheetAction('Edit', 'edit', icon: Icons.edit_outlined),
        SheetAction(c.isActive ? 'Remove' : 'Restore', 'hide', icon: Icons.visibility_off_outlined),
      ],
    );
    if (action == 'edit' && context.mounted) await _edit(context, ref, c);
    if (action == 'hide') {
      await ref.read(categoryRepoProvider).upsert(
            c.copyWith(isActive: !c.isActive, updatedAt: DateTime.now().toUtc()),
          );
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Category? existing, {int sort = 0}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final icon = TextEditingController(text: existing?.icon ?? '✨');
    var color = existing?.accentColor ?? 0xFF6D5EF7;
    const palette = [0xFF6D5EF7, 0xFFFF7A59, 0xFF1ED6A5, 0xFF4C8DFF, 0xFFE85D8C, 0xFFFFB020];
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.viewInsetsOf(ctx).bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                  const SizedBox(height: 8),
                  TextField(controller: icon, decoration: const InputDecoration(labelText: 'Icon')),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final c in palette)
                        GestureDetector(
                          onTap: () => setLocal(() => color = c),
                          child: CircleAvatar(
                            backgroundColor: Color(c),
                            child: color == c ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
                ],
              ),
            );
          },
        );
      },
    );
    if (ok != true || name.text.trim().isEmpty) return;
    final now = DateTime.now().toUtc();
    final cat = existing?.copyWith(
          name: name.text.trim(),
          icon: icon.text.trim().isEmpty ? existing.icon : icon.text.trim(),
          accentColor: color,
          updatedAt: now,
        ) ??
        Category(
          id: newId(),
          userId: ref.read(userIdProvider),
          name: name.text.trim(),
          icon: icon.text.trim().isEmpty ? '✨' : icon.text.trim(),
          accentColor: color,
          isDefault: false,
          isActive: true,
          sortOrder: sort,
          createdAt: now,
          updatedAt: now,
          deviceId: ref.read(deviceIdProvider),
        );
    await ref.read(categoryRepoProvider).upsert(cat);
  }
}
