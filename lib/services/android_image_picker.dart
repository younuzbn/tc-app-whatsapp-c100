import 'package:flutter/services.dart';

/// Android-only image picker via MainActivity MethodChannel.
/// Avoids image_picker plugin MissingPluginException issues.
class AndroidImagePicker {
  AndroidImagePicker._();

  static const MethodChannel _channel = MethodChannel('win_app/image_picker');

  /// Returns local file path, or null if user cancelled.
  static Future<String?> pickImage() async {
    final path = await _channel.invokeMethod<String>('pickImage');
    if (path == null || path.isEmpty) return null;
    return path;
  }
}
