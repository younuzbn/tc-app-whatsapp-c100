import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';
import 'api_http.dart';
import 'session_service.dart';

class ShareInviteConfig {
  const ShareInviteConfig({
    required this.shareText,
    required this.mediaUrl,
    required this.mediaType,
    required this.mediaMime,
    required this.mediaName,
    required this.version,
    required this.hasMedia,
  });

  final String shareText;
  final String mediaUrl;
  final String mediaType;
  final String mediaMime;
  final String mediaName;
  final String version;
  final bool hasMedia;

  factory ShareInviteConfig.fromJson(Map<String, dynamic> json) {
    final url = AppConfig.mediaUrl(json['mediaUrl']?.toString() ?? '');
    return ShareInviteConfig(
      shareText: (json['shareText']?.toString() ?? '').trim(),
      mediaUrl: url,
      mediaType: json['mediaType']?.toString() ?? '',
      mediaMime: json['mediaMime']?.toString() ?? '',
      mediaName: json['mediaName']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      hasMedia: json['hasMedia'] == true || url.isNotEmpty,
    );
  }
}

class ShareReadyMedia {
  const ShareReadyMedia({
    required this.text,
    this.file,
    this.mime,
    this.name,
  });

  final String text;
  final File? file;
  final String? mime;
  final String? name;
}

class ShareMediaCache {
  ShareMediaCache._();

  static final ShareMediaCache instance = ShareMediaCache._();

  static const _defaultText = '''
📲 Download and Install:
{link}

🎁 Use my referral code to get a bonus:
`{code}`
''';

  ShareInviteConfig? _config;
  File? _file;
  Future<void>? _inflight;

  ShareInviteConfig? get config => _config;

  Future<void> prefetch() {
    return _inflight ??= _prefetch().whenComplete(() => _inflight = null);
  }

  Future<ShareReadyMedia> ensureReady() async {
    await prefetch();
    return ShareReadyMedia(
      text: (_config?.shareText.trim().isNotEmpty == true)
          ? _config!.shareText
          : _defaultText.trim(),
      file: _file?.existsSync() == true ? _file : null,
      mime: _config?.mediaMime,
      name: _config?.mediaName,
    );
  }

  Future<ShareInviteConfig> fetchConfig() async {
    final token = SessionService.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Login required');
    }
    final isAdmin = SessionService.isAdmin;
    final path = isAdmin ? '/api/admin/share-config' : '/api/mobile/share-config';
    final response = await http
        .get(
          Uri.parse('${AppConfig.apiBaseUrl}$path'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 12));
    final body = _decode(response.body);
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load share content');
    }
    final data = body['data'] as Map<String, dynamic>? ?? {};
    return ShareInviteConfig.fromJson(data);
  }

  Future<ShareInviteConfig> saveConfig({
    required String shareText,
    String? mediaPath,
  }) async {
    final token = SessionService.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Login required');
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.apiBaseUrl}/api/admin/share-config'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['shareText'] = shareText.trim();
    if (mediaPath != null && mediaPath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('media', mediaPath));
    }
    final streamed = await request.send().timeout(const Duration(minutes: 3));
    final response = await http.Response.fromStream(streamed);
    final body = _decode(response.body);
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to save share content');
    }
    final data = body['data'] as Map<String, dynamic>? ?? {};
    final config = ShareInviteConfig.fromJson(data);
    unawaited(prefetch());
    return config;
  }

  Future<void> _prefetch() async {
    if (!SessionService.isLoggedIn) return;
    try {
      final config = await fetchConfig();
      _config = config;
      if (!config.hasMedia || config.mediaUrl.isEmpty) {
        _file = null;
        await _writeMeta(config);
        return;
      }
      final dir = await _dir();
      final ext = _extFor(config);
      final target = File('${dir.path}/share_v${config.version}$ext');
      if (await target.exists() && await target.length() > 0) {
        _file = target;
        await _writeMeta(config);
        return;
      }
      final response = await http
          .get(Uri.parse(config.mediaUrl))
          .timeout(const Duration(minutes: 3));
      if (response.statusCode >= 400 || response.bodyBytes.isEmpty) return;
      final tmp = File('${target.path}.part');
      await tmp.writeAsBytes(response.bodyBytes, flush: true);
      if (await target.exists()) await target.delete();
      await tmp.rename(target.path);
      await _cleanupOld(dir, keep: target.path);
      _file = target;
      await _writeMeta(config);
    } on SocketException catch (_) {
    } on TimeoutException catch (_) {
    } on http.ClientException catch (_) {
    } catch (error) {
      if (isNetworkError(error)) return;
    }
  }

  Future<Directory> _dir() async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}/share_media');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _writeMeta(ShareInviteConfig config) async {
    try {
      final dir = await _dir();
      await File('${dir.path}/meta.json').writeAsString(
        jsonEncode({
          'version': config.version,
          'shareText': config.shareText,
          'mediaUrl': config.mediaUrl,
          'mediaType': config.mediaType,
          'mediaMime': config.mediaMime,
          'mediaName': config.mediaName,
        }),
      );
    } catch (_) {}
  }

  Future<void> _cleanupOld(Directory dir, {required String keep}) async {
    await for (final entity in dir.list()) {
      if (entity is File &&
          entity.path != keep &&
          !entity.path.endsWith('meta.json')) {
        try {
          await entity.delete();
        } catch (_) {}
      }
    }
  }

  String _extFor(ShareInviteConfig config) {
    final name = config.mediaName.toLowerCase();
    final dot = name.lastIndexOf('.');
    if (dot >= 0 && dot < name.length - 1) {
      return name.substring(dot);
    }
    if (config.mediaMime.contains('png')) return '.png';
    if (config.mediaMime.contains('webp')) return '.webp';
    if (config.mediaMime.contains('gif')) return '.gif';
    if (config.mediaMime.startsWith('video/')) return '.mp4';
    if (config.mediaMime.startsWith('image/')) return '.jpg';
    return '';
  }

  Map<String, dynamic> _decode(String body) {
    if (body.isEmpty) return {};
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : {};
  }
}
