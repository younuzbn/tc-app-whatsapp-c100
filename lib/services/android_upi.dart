import 'dart:convert';

import 'package:flutter/services.dart';

class InstalledUpiApp {
  const InstalledUpiApp({
    required this.name,
    required this.packageName,
    this.iconBytes,
  });

  final String name;
  final String packageName;
  final Uint8List? iconBytes;

  bool get isGpay =>
      packageName == 'com.google.android.apps.nbu.paisa.user';
}

class AndroidUpi {
  AndroidUpi._();

  static const MethodChannel _channel = MethodChannel('win_app/upi');
  static const _gpayPackage = 'com.google.android.apps.nbu.paisa.user';

  /// P2P pay link. Do not add `tr` / dummy `mc` — GPay treats those as an
  /// unsigned merchant collect, so the first PIN attempt fails and only a
  /// retry from the GPay chat succeeds.
  static String buildPayUri({
    required String upiId,
    required String payeeName,
    required double amount,
    String merchantCode = '',
    String note = 'Win App',
    String packageName = '',
  }) {
    final pa = upiId.trim().toLowerCase();
    final pn = payeeName.trim().isEmpty ? 'Win App' : payeeName.trim();
    final tn = note.trim().isEmpty ? 'Win App' : note.trim();
    final am = amount.toStringAsFixed(2);
    final parts = <String>[
      'pa=$pa',
      'pn=${_enc(pn)}',
      'am=$am',
      'cu=INR',
      'tn=${_enc(tn)}',
    ];
    final mc = merchantCode.trim();
    if (RegExp(r'^\d{4}$').hasMatch(mc) && mc != '0000') {
      parts.add('mc=$mc');
    }
    final query = parts.join('&');
    if (packageName == _gpayPackage) {
      return 'tez://upi/pay?$query';
    }
    return 'upi://pay?$query';
  }

  static String _enc(String value) => Uri.encodeComponent(value);

  static Future<List<InstalledUpiApp>> listInstalledApps() async {
    final raw = await _channel.invokeMethod<List<dynamic>>('listApps');
    if (raw == null) return const [];
    final apps = <InstalledUpiApp>[];
    final seen = <String>{};
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final packageName = map['packageName']?.toString() ?? '';
      final name = map['name']?.toString() ?? packageName;
      if (packageName.isEmpty || !seen.add(packageName)) continue;
      Uint8List? iconBytes;
      final icon = map['iconBase64']?.toString() ?? '';
      if (icon.isNotEmpty) {
        try {
          iconBytes = base64Decode(icon);
        } catch (_) {}
      }
      apps.add(
        InstalledUpiApp(
          name: name,
          packageName: packageName,
          iconBytes: iconBytes,
        ),
      );
    }
    apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return apps;
  }

  static Future<void> launch({
    required String uri,
    String packageName = '',
  }) async {
    await _channel.invokeMethod<void>('launch', {
      'uri': uri,
      'packageName': packageName,
    });
  }
}
