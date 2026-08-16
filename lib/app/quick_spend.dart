import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/ids.dart';
import '../core/utils/money.dart';
import '../domain/entities/entities.dart';
import '../domain/enums/enums.dart';
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

Future<void> importWidgetInbox(WidgetRef ref) async {
  if (ref.read(sessionProfileProvider) == null) return;
  try {
    final raw = await widgetChannel.invokeMethod<List<dynamic>>('drainInbox');
    if (raw == null || raw.isEmpty) return;
    for (final item in raw) {
      final map = Map<String, dynamic>.from(item as Map);
      final amount = map['amountMinor'];
      final minor = amount is int ? amount : int.tryParse('$amount') ?? 0;
      if (minor <= 0) continue;
      await recordNamedSpend(
        ref,
        id: map['id'] as String?,
        amountMinor: minor,
        what: map['what'] as String?,
      );
    }
  } catch (_) {}
}

void listenForWidgetSpends(WidgetRef ref) {
  widgetChannel.setMethodCallHandler((call) async {
    if (call.method != 'widgetSpend') return;
    if (ref.read(sessionProfileProvider) == null) return;
    final args = Map<String, dynamic>.from(call.arguments as Map);
    final amount = args['amountMinor'];
    final minor = amount is int ? amount : int.tryParse('$amount') ?? 0;
    if (minor <= 0) return;
    await recordNamedSpend(
      ref,
      id: args['id'] as String?,
      amountMinor: minor,
      what: args['what'] as String?,
    );
  });
}

Future<void> handleLaunchUri(WidgetRef ref, String raw) async {
  final uri = Uri.tryParse(raw);
  if (uri == null || uri.scheme != 'spendping') return;
  if (uri.host == 'compose') {
    ref.read(pendingRouteProvider.notifier).state = '/compose';
    return;
  }
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
  String? id,
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
    id: (id != null && id.isNotEmpty) ? id : newId(),
    userId: ref.read(userIdProvider),
    amount: Money(minorUnits: amountMinor),
    categoryId: cat.id,
    paymentMethod: settings.lastPaymentMethod,
    note: what == null || what.trim().isEmpty ? null : what.trim(),
    timestamp: now,
    createdAt: now,
    updatedAt: now,
    deviceId: ref.read(deviceIdProvider),
    source: ExpenseSource.shortcut,
  );
  await ref.read(expenseRepoProvider).upsert(expense);
  await ref.read(settingsRepoProvider).save(settings.copyWith(lastCategoryId: cat.id));
  return expense;
}

