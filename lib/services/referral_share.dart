import 'dart:io';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_config.dart';

const referShareAssetPath = 'assets/win_app_v3.png';

String referralShareText(String code) {
  final formatted = code.trim().toUpperCase();
  return '''
📲 Download and Install:
${AppConfig.appDownloadUrl}

🎁 Use my referral code to get a bonus:
`$formatted`
'''
      .trim();
}

Future<void> shareWinAppInvite(String code) async {
  final data = await rootBundle.load(referShareAssetPath);
  final file = File('${Directory.systemTemp.path}/win-app-refer.png');
  await file.writeAsBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    flush: true,
  );
  await SharePlus.instance.share(
    ShareParams(
      text: referralShareText(code),
      files: [
        XFile(file.path, mimeType: 'image/png', name: 'win-app-refer.png'),
      ],
    ),
  );
}
