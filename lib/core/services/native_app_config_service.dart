import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeAppConfigService {
  static const MethodChannel _channel =
      MethodChannel('online_booking/app_config');

  Future<bool> hasGoogleMapsApiKey() async {
    if (kIsWeb) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('hasGoogleMapsApiKey');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getTimeZoneId() async {
    try {
      final result = await _channel.invokeMethod<String>('getTimeZoneId');
      final value = result?.trim();
      return value == null || value.isEmpty ? null : value;
    } catch (_) {
      return null;
    }
  }
}
