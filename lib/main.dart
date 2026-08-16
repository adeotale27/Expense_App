import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'data/local/app_database.dart';
import 'data/remote/auth_service.dart';
import 'data/sync/sync_engine.dart';
import 'location/location_provider.dart';
import 'notifications/notification_service.dart';

const _launchChannel = MethodChannel('spendping/launch');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.tryInit();

  final db = await AppDatabase.file();
  final session = SessionStore();
  final deviceId = await session.deviceId();
  final user = await session.current();
  final notifications = NotificationService();
  await notifications.initialize();
  final simulator = SimulatedLocationProvider();
  final location = Platform.isIOS
      ? IOSLocationProvider()
      : AndroidLocationProvider();

  final merged = _MergedLocationProvider(platform: location, simulator: simulator);

  final remote = FirebaseBootstrap.available && user != null
      ? FirestoreRemoteStore(user.id)
      : MemoryRemoteStore();

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      deviceIdProvider.overrideWithValue(deviceId),
      sessionProfileProvider.overrideWith((ref) => user),
      notificationServiceProvider.overrideWithValue(notifications),
      simulatorProvider.overrideWithValue(simulator),
      locationProviderAdapter.overrideWithValue(merged),
      remoteStoreProvider.overrideWithValue(remote),
    ],
  );

  notifications.onAction = (payload, actionId) {
    if (payload.startsWith('opp:')) {
      container.read(pendingRouteProvider.notifier).state =
          actionId == 'no' ? '/inbox' : '/add';
    } else if (payload.startsWith('suggest:')) {
      container.read(pendingRouteProvider.notifier).state = '/home';
    }
  };

  try {
    final launch = await _launchChannel.invokeMethod<String>('consumeLaunch');
    if (launch != null && launch.contains('add')) {
      final uri = Uri.tryParse(launch);
      final amount = uri?.queryParameters['amount'];
      container.read(pendingRouteProvider.notifier).state =
          amount == null ? '/add' : '/add?amount=$amount';
    }
  } catch (_) {}

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SpendPingApp(),
    ),
  );
}

class _MergedLocationProvider implements LocationProvider {
  _MergedLocationProvider({required this.platform, required this.simulator});

  final LocationProvider platform;
  final SimulatedLocationProvider simulator;

  @override
  Stream<GeoFix> get fixes =>
      Stream<GeoFix>.multi((listener) {
        final a = platform.fixes.listen(listener.add, onError: listener.addError);
        final b = simulator.fixes.listen(listener.add, onError: listener.addError);
        listener
          ..onPause = () {
            a.pause();
            b.pause();
          }
          ..onResume = () {
            a.resume();
            b.resume();
          }
          ..onCancel = () async {
            await a.cancel();
            await b.cancel();
          };
      });

  @override
  Future<GeoFix?> getCurrentLocation() async {
    return await simulator.getCurrentLocation() ??
        await platform.getCurrentLocation();
  }

  @override
  Future<bool> hasPermission() => platform.hasPermission();

  @override
  Future<void> initialize() => platform.initialize();

  @override
  Future<bool> requestPermission() => platform.requestPermission();

  @override
  Future<void> startMonitoring() => platform.startMonitoring();

  @override
  Future<void> stopMonitoring() => platform.stopMonitoring();
}
