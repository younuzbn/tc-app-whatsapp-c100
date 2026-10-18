import 'package:share_plus/share_plus.dart';

import '../config/app_config.dart';
import 'share_media_cache.dart';

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

String referralShareText(String code, {String? template}) {
  final formatted = code.trim().toUpperCase();
  final link = referralInviteUrl(formatted);
  var text = (template ?? '').trim();
  if (text.isEmpty) {
    text = '''
📲 Download and Install:
{link}

🎁 Use my referral code to get a bonus:
`$formatted`
'''
        .trim();
  }
  final hadLink = text.contains('{link}');
  final hadCode = text.contains('{code}') || text.contains('{referral}');
  text = text
      .replaceAll('{link}', link)
      .replaceAll('{code}', formatted)
      .replaceAll('{referral}', formatted);
  if (!hadLink) text = '$text\n\n$link';
  if (!hadCode && formatted.isNotEmpty) text = '$text\n`$formatted`';
  return text.trim();
}

Future<void> shareWinAppInvite(String code) async {
  final ready = await ShareMediaCache.instance.ensureReady();
  final files = <XFile>[];
  final file = ready.file;
  if (file != null) {
    files.add(
      XFile(
        file.path,
        mimeType: (ready.mime != null && ready.mime!.isNotEmpty)
            ? ready.mime
            : null,
        name: (ready.name != null && ready.name!.isNotEmpty)
            ? ready.name
            : file.uri.pathSegments.last,
      ),
    );
  }
  await SharePlus.instance.share(
    ShareParams(
      text: referralShareText(code, template: ready.text),
      files: files,
    ),
  );
}
