import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'quick_spend.dart';
import 'router.dart';
import 'theme.dart';

class SpendPingApp extends ConsumerStatefulWidget {
  const SpendPingApp({super.key});

  @override
  ConsumerState<SpendPingApp> createState() => _SpendPingAppState();
}

class _SpendPingAppState extends ConsumerState<SpendPingApp> {
  @override
  void initState() {
    super.initState();
    launchChannel.setMethodCallHandler((call) async {
      if (call.method == 'opened' && call.arguments is String) {
        ref.read(pendingLaunchUriProvider.notifier).state = call.arguments as String;
      }
    });
    listenForWidgetSpends(ref);
    Future<void>.microtask(() async {
      await importWidgetInbox(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final user = ref.watch(sessionProfileProvider);
    ref.listen<String?>(pendingRouteProvider, (prev, next) {
      if (next == null || next.isEmpty) return;
      router.go(next);
      ref.read(pendingRouteProvider.notifier).state = null;
    });
    ref.listen<String?>(pendingLaunchUriProvider, (prev, next) {
      if (next == null || next.isEmpty) return;
      handleLaunchUri(ref, next);
      ref.read(pendingLaunchUriProvider.notifier).state = null;
    });
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
