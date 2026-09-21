import 'dart:io';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_config.dart';

const referShareAssetPath = 'assets/lalrefer.jpeg';

String referralInviteUrl(String code) {
  final formatted = code.trim().toUpperCase();
  final base = Uri.parse(AppConfig.appDownloadUrl);
  if (formatted.isEmpty) return AppConfig.appDownloadUrl;
  return base.replace(queryParameters: {'ref': formatted}).toString();
}

String? parseInviteReferral(String? raw) {
  if (raw == null) return null;
  final text = raw.trim();
  if (text.isEmpty) return null;

  final urlMatch = RegExp(r'https?://[^\s]+', caseSensitive: false).firstMatch(text);
  if (urlMatch != null) {
    final uri = Uri.tryParse(urlMatch.group(0)!);
    final fromQuery =
        uri?.queryParameters['ref'] ?? uri?.queryParameters['referral'];
    final fromUrl = _normalizeReferral(fromQuery);
    if (fromUrl != null) return fromUrl;
  }

  final named = RegExp(
    r'\b((?:WIN|ADM)[A-Z0-9]{4,10})\b',
    caseSensitive: false,
  ).firstMatch(text);
  if (named != null) return named.group(1)!.toUpperCase();

  return _normalizeReferral(text);
}

String? _normalizeReferral(String? raw) {
  final value = (raw ?? '').trim().toUpperCase().replaceAll(
    RegExp(r'[^A-Z0-9]'),
    '',
  );
  if (value.length < 6 || value.length > 12) return null;
  if (!RegExp(r'[A-Z]').hasMatch(value)) return null;
  return value;
}

String referralShareText(String code) {
  final formatted = code.trim().toUpperCase();
  return '''
📲 Download and Install:
${referralInviteUrl(formatted)}

🎁 Use my referral code to get a bonus:
`$formatted`
'''
      .trim();
}

Future<void> shareWinAppInvite(String code) async {
  final data = await rootBundle.load(referShareAssetPath);
  final file = File('${Directory.systemTemp.path}/win-app-refer.jpeg');
  await file.writeAsBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    flush: true,
  );
  await SharePlus.instance.share(
    ShareParams(
      text: referralShareText(code),
      files: [
        XFile(file.path, mimeType: 'image/jpeg', name: 'win-app-refer.jpeg'),
      ],
    ),
  );
}
