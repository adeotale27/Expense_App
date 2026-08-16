import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../people/add_friend_sheet.dart';
import '../places/places_screen.dart';

class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final index = navigationShell.currentIndex;
    final tooltip = switch (index) {
      2 => 'Remember this place',
      3 => 'Add friend',
      _ => 'Add expense',
    };
    return Scaffold(
      body: navigationShell,
      floatingActionButton: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          tooltip: tooltip,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          onPressed: () {
            if (index == 2) {
              showRememberPlaceSheet(context, ref);
            } else if (index == 3) {
              showAddFriendSheet(context, ref);
            } else {
              context.push('/add');
            }
          },
          child: const Icon(Icons.add_rounded, size: 32),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: navigationShell.goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Spends',
          ),
          NavigationDestination(
            icon: Icon(Icons.place_outlined),
            selectedIcon: Icon(Icons.place),
            label: 'Places',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Friends',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
