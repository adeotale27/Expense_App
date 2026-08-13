import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/enums/enums.dart';
import '../../domain/repositories/repositories.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _titleTaps = 0;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            _titleTaps++;
            if (_titleTaps >= 7) {
              _titleTaps = 0;
              context.push('/developer');
            }
          },
          child: const Text('More'),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (s) => ListView(
          children: [
            ListTile(
              title: const Text('Analytics'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/analytics'),
            ),
            ListTile(
              title: const Text('Categories'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/categories'),
            ),
            ListTile(
              title: const Text('Expenses to review'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/inbox'),
            ),
            const Divider(),
            ListTile(
              title: const Text('Appearance'),
              subtitle: Text(s.themeMode),
              onTap: () async {
                final next = switch (s.themeMode) {
                  'system' => 'light',
                  'light' => 'dark',
                  _ => 'system',
                };
                await ref.read(settingsRepoProvider).save(s.copyWith(themeMode: next));
              },
            ),
            ListTile(
              title: const Text('Prompt style'),
              subtitle: Text(s.promptStyle.label),
              onTap: () async {
                final styles = PromptStyle.values;
                final i = (styles.indexOf(s.promptStyle) + 1) % styles.length;
                await ref
                    .read(settingsRepoProvider)
                    .save(s.copyWith(promptStyle: styles[i]));
              },
            ),
            SwitchListTile(
              title: const Text('Ask after leaving a place'),
              value: s.askAfterLeaving,
              onChanged: (v) =>
                  ref.read(settingsRepoProvider).save(s.copyWith(askAfterLeaving: v)),
            ),
            SwitchListTile(
              title: const Text('Ask after returning home'),
              value: s.askAfterReturningHome,
              onChanged: (v) => ref
                  .read(settingsRepoProvider)
                  .save(s.copyWith(askAfterReturningHome: v)),
            ),
            SwitchListTile(
              title: const Text('Evening review'),
              value: s.eveningReview,
              onChanged: (v) =>
                  ref.read(settingsRepoProvider).save(s.copyWith(eveningReview: v)),
            ),
            ListTile(
              title: const Text('Minimum stop duration'),
              subtitle: Text('${s.minStopMinutes} minutes'),
              onTap: () async {
                const opts = [3, 5, 10, 15];
                final i = (opts.indexOf(s.minStopMinutes) + 1) % opts.length;
                await ref
                    .read(settingsRepoProvider)
                    .save(s.copyWith(minStopMinutes: opts[i]));
              },
            ),
            ListTile(
              title: const Text('Maximum daily prompts'),
              subtitle: Text('${s.maxDailyPrompts}'),
              onTap: () async {
                final next = s.maxDailyPrompts >= 10 ? 1 : s.maxDailyPrompts + 1;
                await ref
                    .read(settingsRepoProvider)
                    .save(s.copyWith(maxDailyPrompts: next));
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Enable location'),
              subtitle: const Text(
                'SpendPing uses location to notice meaningful places and remind you to record expenses. The app still works if you decline.',
              ),
              onTap: () async {
                final ok = await ref
                    .read(locationProviderAdapter)
                    .requestPermission();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Location enabled'
                          : 'Smart location reminders are paused. You can continue using the app manually.',
                    ),
                    action: ok
                        ? null
                        : SnackBarAction(
                            label: 'Settings',
                            onPressed: openAppSettings,
                          ),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Enable notifications'),
              onTap: () async {
                final ok = await ref
                    .read(notificationServiceProvider)
                    .requestPermission();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Notifications on'
                          : 'Smart reminders are off. You can still review possible expenses inside the app.',
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Export data'),
              onTap: () => _export(ref),
            ),
            ListTile(
              title: const Text('Sync now'),
              onTap: () async {
                try {
                  await ref.read(syncEngineProvider).syncAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sync: ${ref.read(syncEngineProvider).status}')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not reach cloud sync.')),
                    );
                  }
                }
              },
            ),
            ListTile(
              title: const Text('Sign out'),
              onTap: () async {
                await ref.read(authServiceProvider).signOut();
                ref.read(sessionProfileProvider.notifier).state = null;
                if (context.mounted) context.go('/welcome');
              },
            ),
            ListTile(
              title: Text(
                'Delete account data',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete your data?'),
                    content: const Text(
                      'This removes SpendPing data stored on this device for your account.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await ref.read(databaseProvider).close();
                  // Recreate empty file by deleting sqlite is heavy; sign out instead
                  // and leave a note. Full wipe:
                  final dir = await getApplicationDocumentsDirectory();
                  final file = File('${dir.path}/spendping.sqlite');
                  if (await file.exists()) await file.delete();
                  await ref.read(authServiceProvider).signOut();
                  ref.read(sessionProfileProvider.notifier).state = null;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data deleted. Restart the app to continue.'),
                      ),
                    );
                    context.go('/welcome');
                  }
                }
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                '${AppConstants.appName}  v${_version()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _version() => '1.0.0';

  Future<void> _export(WidgetRef ref) async {
    final expenses = await ref.read(expenseRepoProvider).list(
          const ExpenseQuery(limit: 10000),
        );
    final payload = {
      'app': 'SpendPing',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'expenses': [
        for (final e in expenses)
          {
            'id': e.id,
            'amountMinor': e.amount.minorUnits,
            'currency': e.amount.currencyCode,
            'categoryId': e.categoryId,
            'note': e.note,
            'timestamp': e.timestamp.toIso8601String(),
          }
      ],
    };
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/spendping-export.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    await Share.shareXFiles([XFile(file.path)], text: 'SpendPing export');
  }
}
