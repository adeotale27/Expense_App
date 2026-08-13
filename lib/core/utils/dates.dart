import 'package:intl/intl.dart';

DateTime utcNow() => DateTime.now().toUtc();

DateTime startOfLocalDay(DateTime local) =>
    DateTime(local.year, local.month, local.day);

DateTime endOfLocalDay(DateTime local) =>
    DateTime(local.year, local.month, local.day, 23, 59, 59, 999);

DateTime startOfLocalMonth(DateTime local) =>
    DateTime(local.year, local.month, 1);

String greetingFor(DateTime local) {
  final hour = local.hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String formatTime(DateTime local) => DateFormat('HH:mm').format(local);

String formatDay(DateTime local) {
  final now = DateTime.now();
  final d = DateTime(local.year, local.month, local.day);
  final today = DateTime(now.year, now.month, now.day);
  if (d == today) return 'Today';
  if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
  return DateFormat('EEE, d MMM').format(local);
}

String monthTitle(DateTime local) => DateFormat('MMMM').format(local);
