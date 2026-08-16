import 'package:flutter/services.dart';

class AppHaptics {
  static Future<void> tap() => HapticFeedback.selectionClick();
  static Future<void> confirm() => HapticFeedback.mediumImpact();
  static Future<void> warn() => HapticFeedback.heavyImpact();
}
