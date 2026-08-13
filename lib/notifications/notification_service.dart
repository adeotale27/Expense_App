import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/logging/app_log.dart';
import '../domain/entities/entities.dart';

class NotificationService {
  NotificationService();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool ready = false;
  final List<String> queue = [];

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    ready = true;
  }

  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> hasPermission() async {
    return Permission.notification.isGranted;
  }

  Future<void> showOpportunity(ExpenseOpportunity opp, Place place) async {
    final emoji = switch (place.type.name) {
      'grocery' => '🛒',
      'fuel' => '⛽',
      'food' => '🍛',
      _ => '📍',
    };
    final title = '$emoji Did you spend anything at ${place.name.toLowerCase()}?';
    queue.add(opp.id);
    AppLog.notification('Prompt scheduled ${opp.id}');
    if (!ready) return;
    await _plugin.show(
      opp.id.hashCode,
      'SpendPing',
      title,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'opportunities',
          'Expense reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: opp.id,
    );
  }

  Future<void> showEveningReview({required int recorded, required int pending}) async {
    if (!ready) return;
    await _plugin.show(
      9001,
      '🌙 Finish your day',
      'You recorded $recorded expenses. $pending possible expenses remain.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reviews',
          'Daily review',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
