import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';

class AppVersionInfo {
  const AppVersionInfo({
    required this.latestVersion,
    required this.updateMode,
    required this.downloadUrl,
    required this.available,
  });

  final String latestVersion;
  final String updateMode;
  final String downloadUrl;
  final bool available;

  bool get isOptional => updateMode == 'optional';
  bool get isForce => updateMode == 'force';
}

class AppUpdateStatus {
  const AppUpdateStatus({
    required this.currentVersion,
    required this.info,
  });

  final String currentVersion;
  final AppVersionInfo? info;

  bool get hasNewer {
    final latest = info?.latestVersion ?? '';
    if (latest.isEmpty) return false;
    return compareVersions(currentVersion, latest) < 0;
  }

  bool get showOptional => hasNewer && info?.isOptional == true;
  bool get showForce => hasNewer && info?.isForce == true;
}

class AppUpdateService {
  const AppUpdateService();

  String get currentVersion => AppConfig.appVersion;

  Future<AppUpdateStatus> check() async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/app-version');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final info = AppVersionInfo(
        latestVersion: data['version']?.toString() ?? '',
        updateMode: data['updateMode']?.toString() ?? 'off',
        downloadUrl: data['downloadUrl']?.toString() ?? AppConfig.appDownloadUrl,
        available: data['available'] == true,
      );
      return AppUpdateStatus(currentVersion: currentVersion, info: info);
    } on SocketException {
      return AppUpdateStatus(currentVersion: currentVersion, info: null);
    } on TimeoutException {
      return AppUpdateStatus(currentVersion: currentVersion, info: null);
    } catch (_) {
      return AppUpdateStatus(currentVersion: currentVersion, info: null);
    }
  }

  Future<void> openDownloadPage([String? url]) async {
    final uri = Uri.parse(url ?? AppConfig.appDownloadUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

int compareVersions(String a, String b) {
  List<int> parts(String value) => value
      .split(RegExp(r'[.+-]'))
      .where((part) => part.isNotEmpty)
      .map((part) => int.tryParse(part) ?? 0)
      .toList();
  final left = parts(a);
  final right = parts(b);
  final max = left.length > right.length ? left.length : right.length;
  for (var i = 0; i < max; i++) {
    final l = i < left.length ? left[i] : 0;
    final r = i < right.length ? right[i] : 0;
    if (l != r) return l < r ? -1 : 1;
  }
  return 0;
}
