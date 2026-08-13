import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class SpendPingApp extends ConsumerWidget {
  const SpendPingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final user = ref.watch(sessionProfileProvider);
    var themeMode = ThemeMode.system;
    if (user != null) {
      themeMode = ref.watch(settingsProvider).maybeWhen(
            data: (s) => switch (s.themeMode) {
              'light' => ThemeMode.light,
              'dark' => ThemeMode.dark,
              _ => ThemeMode.system,
            },
            orElse: () => ThemeMode.system,
          );
    }
    return MaterialApp.router(
      title: 'SpendPing',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
