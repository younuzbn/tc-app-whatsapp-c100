import 'package:flutter/services.dart';

class DeviceIdService {
  DeviceIdService._();

  static const _channel = MethodChannel('win_app/session');
  static String? _cached;

  static Future<String> getId() async {
    if (_cached != null && _cached!.isNotEmpty) return _cached!;
    try {
      final value = await _channel.invokeMethod<String>('getDeviceId');
      _cached = (value ?? '').trim();
    } catch (_) {
      _cached = '';
    }
    return _cached ?? '';
  }
}
