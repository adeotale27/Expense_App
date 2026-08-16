import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/logging/app_log.dart';
import '../domain/entities/entities.dart';

typedef NotificationTap = void Function(String payload, String? actionId);

class NotificationService {
  NotificationService();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool ready = false;
  final List<String> queue = [];
  NotificationTap? onAction;

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'opportunity',
          actions: [
            DarwinNotificationAction.plain('yes', 'Yes'),
            DarwinNotificationAction.plain('no', 'Not this time'),
          ],
        ),
      ],
    );
    await _plugin.initialize(
      InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload == null) return;
        onAction?.call(payload, resp.actionId);
      },
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
    final title = '📍 ${place.name}';
    const body = 'Did you spend anything here?';
    queue.add(opp.id);
    AppLog.notification('Prompt scheduled ${opp.id}');
    if (!ready) return;
    await _plugin.show(
      opp.id.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'opportunities',
          'Expense reminders',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction('yes', 'Yes, record it'),
            AndroidNotificationAction('no', 'Not this time'),
          ],
        ),
        iOS: DarwinNotificationDetails(categoryIdentifier: 'opportunity'),
      ),
      payload: 'opp:${opp.id}',
    );
  }

  Future<void> showPlaceSuggestion(PlaceSuggestion suggestion) async {
    if (!ready) return;
    await _plugin.show(
      suggestion.place.id.hashCode,
      suggestion.headline,
      suggestion.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'suggestions',
          'Place suggestions',
          importance: Importance.defaultImportance,
          actions: [
            AndroidNotificationAction('yes', 'Yes'),
            AndroidNotificationAction('no', 'No'),
          ],
        ),
        iOS: DarwinNotificationDetails(categoryIdentifier: 'opportunity'),
      ),
      payload: 'suggest:${suggestion.kind.name}:${suggestion.place.id}',
    );
  }

  Future<void> showEveningReview({required int recorded, required int pending}) async {
    if (!ready) return;
    await _plugin.show(
      9001,
      'Finish your day',
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
