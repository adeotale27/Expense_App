import 'package:flutter/foundation.dart';

class AppLog {
  static void location(String message) => _emit('LOCATION', message);
  static void place(String message) => _emit('PLACE', message);
  static void movement(String message) => _emit('MOVEMENT', message);
  static void opportunity(String message) => _emit('OPPORTUNITY', message);
  static void notification(String message) => _emit('NOTIFICATION', message);
  static void expense(String message) => _emit('EXPENSE', message);
  static void sync(String message) => _emit('SYNC', message);
  static void error(String message) => _emit('ERROR', message);

  static void _emit(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }
}
