import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/utils/money.dart';
import '../../domain/enums/enums.dart';
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
                  'Places appear when you visit them or when you use the location simulator in Developer mode.',
            )
          : ListView.builder(
              itemCount: places.length,
              itemBuilder: (context, i) {
                final p = places[i];
                return ListTile(
                  title: Text(p.name),
                  subtitle: Text(p.type.label),
                  trailing: Text(
                    Money(minorUnits: p.totalSpendMinor).format(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () => context.push('/places/${p.id}'),
                );
              },
            ),
    );
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
          appBar: AppBar(title: Text(p.name)),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('${p.visitCount} visits',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Text('Total: ${Money(minorUnits: p.totalSpendMinor).format()}'),
              Text(
                'Average: ${Money(minorUnits: p.averageSpendMinor).format()}',
              ),
              if (p.lastVisitedAt != null)
                Text('Last visit: ${p.lastVisitedAt!.toLocal()}'),
            ],
          ),
        );
      },
    );
  }
}
