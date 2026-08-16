import 'package:flutter/services.dart';

/// Web OAuth client ID from Google Cloud (type 3).
/// Pass at build time: --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com
class GoogleOAuth {
  static const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const mapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static const _widget = MethodChannel('spendping/widget');
  static String? _mapsFromNative;

  static Future<String> resolveMapsKey() async {
    if (mapsApiKey.isNotEmpty) return mapsApiKey;
    if (_mapsFromNative != null) return _mapsFromNative!;
    try {
      _mapsFromNative = await _widget.invokeMethod<String>('mapsKey') ?? '';
    } catch (_) {
      _mapsFromNative = '';
    }
    return _mapsFromNative!;
  }
}

