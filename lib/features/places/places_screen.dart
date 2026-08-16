import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/utils/ids.dart';
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
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 108),
              itemCount: places.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final p = places[i];
                return QuietCard(
                  onTap: () => context.push('/places/${p.id}'),
                  child: GestureDetector(
                    onLongPress: () => _placeActions(context, ref, p),
                    child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
                        child: Text(_emoji(p.type), style: const TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                            Text('${p.type.label} · ${p.visitCount} visits'),
                          ],
                        ),
                      ),
                      Text(
                        Money(minorUnits: p.totalSpendMinor).format(),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  ),
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              GradientHero(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_emoji(p.type)} ${p.type.label}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      Money(minorUnits: p.totalSpendMinor).format(),
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
                    ),
                    Text('${p.visitCount} visits · nothing auto-logged'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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

Future<void> showRememberPlaceSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _RememberPlaceForm(),
  );
}

class _RememberPlaceForm extends ConsumerStatefulWidget {
  const _RememberPlaceForm();

  @override
  ConsumerState<_RememberPlaceForm> createState() => _RememberPlaceFormState();
}

class _RememberPlaceFormState extends ConsumerState<_RememberPlaceForm> {
  final name = TextEditingController();
  bool saving = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final label = name.text.trim();
    if (label.isEmpty || saving) return;
    setState(() {
      saving = true;
      error = null;
    });
    final loc = await ref.read(locationProviderAdapter).getCurrentLocation();
    if (loc == null) {
      setState(() {
        saving = false;
        error = 'Turn on location so we can pin this place.';
      });
      return;
    }
    final now = DateTime.now().toUtc();
    await ref.read(placeRepoProvider).upsert(
          Place(
            id: newId(),
            userId: ref.read(userIdProvider),
            name: label,
            type: PlaceType.unknown,
            latitude: loc.latitude,
            longitude: loc.longitude,
            radius: 150,
            userConfirmedName: true,
            geofenceEnabled: true,
            visitCount: 1,
            firstVisitedAt: now,
            lastVisitedAt: now,
            createdAt: now,
            updatedAt: now,
            deviceId: ref.read(deviceIdProvider),
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Remember this place', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Uses your current GPS. SpendPing still will not log an expense until you confirm.'),
          const SizedBox(height: 12),
          TextField(
            controller: name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _save,
            child: Text(saving ? 'Saving…' : 'Save place'),
          ),
        ],
      ),
    );
  }
}
