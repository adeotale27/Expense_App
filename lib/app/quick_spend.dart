import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/ids.dart';
import '../core/utils/money.dart';
import '../domain/entities/entities.dart';
import 'providers.dart';

const launchChannel = MethodChannel('spendping/launch');
const widgetChannel = MethodChannel('spendping/widget');

Future<void> publishTodayTotal(int minorUnits) async {
  try {
    await widgetChannel.invokeMethod('publishToday', {
      'total': Money(minorUnits: minorUnits).format(),
    });
  } catch (_) {}
}

Future<void> handleLaunchUri(WidgetRef ref, String raw) async {
  final uri = Uri.tryParse(raw);
  if (uri == null || uri.scheme != 'spendping') return;
  final amount = int.tryParse(uri.queryParameters['amount'] ?? '');
  final what = uri.queryParameters['what'] ?? uri.queryParameters['category'];
  final quick = uri.host == 'quick' || uri.queryParameters['quick'] == '1';
  if (ref.read(sessionProfileProvider) == null) {
    final q = <String>[];
    if (amount != null) q.add('amount=$amount');
    if (what != null && what.isNotEmpty) q.add('what=${Uri.encodeComponent(what)}');
    ref.read(pendingRouteProvider.notifier).state =
        q.isEmpty ? '/add' : '/add?${q.join('&')}';
    return;
  }
  if (quick && amount != null && amount > 0) {
    await recordNamedSpend(ref, amountMinor: amount, what: what);
    ref.read(pendingRouteProvider.notifier).state = '/home';
    return;
  }
  final q = <String>[];
  if (amount != null) q.add('amount=$amount');
  if (what != null && what.isNotEmpty) q.add('what=${Uri.encodeComponent(what)}');
  ref.read(pendingRouteProvider.notifier).state =
      q.isEmpty ? '/add' : '/add?${q.join('&')}';
}

Future<Expense?> recordNamedSpend(
  WidgetRef ref, {
  required int amountMinor,
  String? what,
}) async {
  await ref.read(categoryRepoProvider).ensureDefaults();
  final cats = await ref.read(categoryRepoProvider).all();
  final needle = (what ?? '').trim().toLowerCase();
  Category? cat;
  if (needle.isNotEmpty) {
    cat = cats.where((c) => c.name.toLowerCase() == needle).firstOrNull;
    cat ??= cats.where((c) => c.name.toLowerCase().contains(needle)).firstOrNull;
  }
  cat ??= cats.where((c) => c.name == 'Other').firstOrNull;
  cat ??= cats.firstOrNull;
  if (cat == null) return null;
  final settings = await ref.read(settingsRepoProvider).get(ref.read(userIdProvider));
  final now = DateTime.now().toUtc();
  final expense = Expense(
    id: newId(),
    userId: ref.read(userIdProvider),
    amount: Money(minorUnits: amountMinor),
    categoryId: cat.id,
    paymentMethod: settings.lastPaymentMethod,
    note: what == null || what.trim().isEmpty ? null : what.trim(),
    timestamp: now,
    createdAt: now,
    updatedAt: now,
    deviceId: ref.read(deviceIdProvider),
  );
  await ref.read(expenseRepoProvider).upsert(expense);
  await ref.read(settingsRepoProvider).save(settings.copyWith(lastCategoryId: cat.id));
  return expense;
}

