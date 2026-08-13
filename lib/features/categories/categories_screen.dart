import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: ReorderableListView(
        onReorder: (a, b) async {
          final list = [...cats];
          final item = list.removeAt(a);
          list.insert(b > a ? b - 1 : b, item);
          for (var i = 0; i < list.length; i++) {
            await ref.read(categoryRepoProvider).upsert(
                  list[i].copyWith(sortOrder: i, updatedAt: DateTime.now().toUtc()),
                );
          }
        },
        children: [
          for (final c in cats)
            SwitchListTile(
              key: ValueKey(c.id),
              title: Text('${c.icon} ${c.name}'),
              value: c.isActive,
              onChanged: (v) => ref.read(categoryRepoProvider).upsert(
                    c.copyWith(isActive: v, updatedAt: DateTime.now().toUtc()),
                  ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final name = TextEditingController();
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Add category'),
              content: TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
              ],
            ),
          );
          if (ok == true && name.text.trim().isNotEmpty) {
            final now = DateTime.now().toUtc();
            await ref.read(categoryRepoProvider).upsert(
                  Category(
                    id: newId(),
                    userId: ref.read(userIdProvider),
                    name: name.text.trim(),
                    icon: '•',
                    isDefault: false,
                    isActive: true,
                    sortOrder: cats.length,
                    createdAt: now,
                    updatedAt: now,
                    deviceId: ref.read(deviceIdProvider),
                  ),
                );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
