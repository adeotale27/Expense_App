import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/utils/money.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/enums.dart';
import '../shared/action_sheet.dart';
import '../shared/widgets.dart';

class PlacesScreen extends ConsumerWidget {
  const PlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(placesProvider).valueOrNull ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Places')),
      body: places.isEmpty
          ? const EmptyState(
              title: 'No places yet',
              subtitle:
                  'Places are remembered when you stay somewhere meaningful. Nothing is logged as an expense until you confirm.',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
              itemCount: places.length,
              itemBuilder: (context, i) {
                final p = places[i];
                return ListTile(
                  leading: Text(_emoji(p.type), style: const TextStyle(fontSize: 22)),
                  title: Text(p.name),
                  subtitle: Text('${p.type.label} · ${p.visitCount} visits'),
                  trailing: Text(
                    Money(minorUnits: p.totalSpendMinor).format(),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onTap: () => context.push('/places/${p.id}'),
                  onLongPress: () => _placeActions(context, ref, p),
                );
              },
            ),
    );
  }
}

String _emoji(PlaceType t) => switch (t) {
      PlaceType.home => '🏠',
      PlaceType.work => '💼',
      PlaceType.food => '🍽️',
      PlaceType.cafe => '☕',
      PlaceType.grocery => '🛒',
      PlaceType.gym => '💪',
      PlaceType.gaming => '🎮',
      PlaceType.cinema => '🎬',
      PlaceType.hangout => '🫶',
      PlaceType.shopping => '🛍️',
      _ => '📍',
    };

Future<void> _placeActions(BuildContext context, WidgetRef ref, Place p) async {
  final action = await showActionSheet<String>(
    context,
    title: p.name,
    actions: const [
      SheetAction('Edit', 'edit', icon: Icons.edit_outlined),
      SheetAction('Rename', 'rename', icon: Icons.badge_outlined),
      SheetAction('Forget', 'forget', icon: Icons.visibility_off_outlined, destructive: true),
    ],
  );
  if (action == 'forget') {
    await ref.read(placeRepoProvider).forget(p.id, DateTime.now().toUtc());
    return;
  }
  if (action == 'rename' || action == 'edit') {
    if (!context.mounted) return;
    context.push('/places/${p.id}');
  }
}

class PlaceDetailScreen extends ConsumerWidget {
  const PlaceDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(placeRepoProvider).getById(id),
      builder: (context, snap) {
        final p = snap.data;
        if (p == null) {
          return const Scaffold(body: Center(child: Text('Place not found')));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(p.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _rename(context, ref, p),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('${p.visitCount} visits', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Text('Total: ${Money(minorUnits: p.totalSpendMinor).format()}'),
              Text('Average: ${Money(minorUnits: p.averageSpendMinor).format()}'),
              if (p.lastVisitedAt != null) Text('Last visit: ${p.lastVisitedAt!.toLocal()}'),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Geofence this place'),
                subtitle: Text('${p.radius.round()}m radius · local only'),
                value: p.geofenceEnabled,
                onChanged: (v) => ref.read(placeRepoProvider).upsert(
                      p.copyWith(geofenceEnabled: v, updatedAt: DateTime.now().toUtc()),
                    ),
              ),
              FilledButton.tonal(
                onPressed: () => context.push('/add?placeId=${p.id}'),
                child: const Text('Record a spend here'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, Place p) async {
    final name = TextEditingController(text: p.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename place'),
        content: TextField(controller: name),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      await ref.read(placeRepoProvider).upsert(
            p.copyWith(
              name: name.text.trim(),
              userConfirmedName: true,
              updatedAt: DateTime.now().toUtc(),
            ),
          );
    }
  }
}
