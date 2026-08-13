import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/providers.dart';
import '../../data/remote/auth_service.dart';

class _Sim {
  const _Sim(this.label, this.start, this.stay, this.duration, this.returnHome);
  final String label;
  final String start;
  final String stay;
  final Duration duration;
  final bool returnHome;
}

class DeveloperScreen extends ConsumerWidget {
  const DeveloperScreen({super.key});

  static const _sims = [
    _Sim('Grocery 7m', 'home', 'grocery', Duration(minutes: 7), true),
    _Sim('Milk 4m', 'home', 'milk', Duration(minutes: 4), true),
    _Sim('Pass restaurant', 'home', 'restaurant', Duration(seconds: 20), true),
    _Sim('Office 8h', 'home', 'office', Duration(hours: 8), false),
    _Sim('Restaurant 45m', 'home', 'restaurant', Duration(minutes: 45), true),
    _Sim('Petrol 6m', 'home', 'petrol', Duration(minutes: 6), true),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runtime = ref.watch(locationRuntimeReadyProvider);
    final sync = ref.watch(syncEngineProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Developer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Location state: ${runtime.state.name}'),
          Text('Current place: ${runtime.currentPlace?.name ?? 'none'}'),
          Text('Last score: ${runtime.lastScore}'),
          Text('Last event: ${runtime.lastEvent}'),
          Text('Sync: ${sync.status}'),
          Text('Firebase: ${FirebaseBootstrap.available}'),
          FutureBuilder(
            future: Permission.location.status,
            builder: (_, s) => Text('Location auth: ${s.data}'),
          ),
          const Divider(),
          const Text('Simulate visit', style: TextStyle(fontWeight: FontWeight.w700)),
          Wrap(
            spacing: 8,
            children: [
              for (final item in _sims)
                FilledButton.tonal(
                  onPressed: () async {
                    await runtime.simulate(
                      startKey: item.start,
                      stayKey: item.stay,
                      stay: item.duration,
                      returnHome: item.returnHome,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Simulated ${item.label}')),
                      );
                    }
                  },
                  child: Text(item.label),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
