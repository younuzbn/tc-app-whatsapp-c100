import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';
import 'page_content_defaults.dart';
import 'session_service.dart';

class PageContentSnapshot {
  const PageContentSnapshot({
    required this.key,
    required this.data,
    required this.version,
  });

  final String key;
  final Map<String, String> data;
  final int version;

  String text(String field) => data[field] ?? '';
}

class PageContentService {
  PageContentService._();

  static final PageContentService instance = PageContentService._();

  final Map<String, PageContentSnapshot> _memory = {};
  Future<void>? _inflight;
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  PageContentSnapshot? cached(String key) => _memory[key];

  void _bump() => revision.value++;

  Future<void> prefetch() {
    return _inflight ??= _prefetch().whenComplete(() => _inflight = null);
  }

  Future<PageContentSnapshot> load(String key) async {
    final fromMemory = _memory[key];
    if (fromMemory != null) {
      unawaited(refresh(key));
      return fromMemory;
    }
    final fromDisk = await _readDisk(key);
    if (fromDisk != null) {
      _memory[key] = fromDisk;
      unawaited(refresh(key));
      return fromDisk;
    }
    return refresh(key);
  }

  Future<PageContentSnapshot> refresh(String key) async {
    try {
      final next = await _fetch(key);
      _memory[key] = next;
      await _writeDisk(next);
      _bump();
      return next;
    } catch (_) {
      return _memory[key] ??
          PageContentSnapshot(
            key: key,
            data: mergePageData(key, null),
            version: 0,
          );
    }
  }

  Future<PageContentSnapshot> saveText({
    required String key,
    required String field,
    required String value,
  }) async {
    final current = _memory[key]?.data ?? mergePageData(key, null);
    return _put(key, {...current, field: value});
  }

  Future<PageContentSnapshot> saveImage({
    required String key,
    required String field,
    required String path,
  }) async {
    final token = SessionService.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Login required');
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.apiBaseUrl}/api/admin/page-content/$key/image'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['imageKey'] = field;
    request.files.add(
      await http.MultipartFile.fromPath(
        'media',
        path,
        contentType: _imageContentType(path),
      ),
    );
    final streamed = await request.send().timeout(const Duration(minutes: 2));
    final response = await http.Response.fromStream(streamed);
    return _storeResponse(key, response);
  }

  Future<void> _prefetch() async {
    if (!SessionService.isLoggedIn) return;
    await Future.wait([
      refresh(kReferEarnPageKey),
      refresh(kPriceChartPageKey),
    ]);
  }

  Future<PageContentSnapshot> _put(
    String key,
    Map<String, String> data,
  ) async {
    final token = SessionService.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Login required');
    }
    final response = await http
        .put(
          Uri.parse('${AppConfig.apiBaseUrl}/api/admin/page-content/$key'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'data': data}),
        )
        .timeout(const Duration(seconds: 20));
    return _storeResponse(key, response);
  }

  Future<PageContentSnapshot> _fetch(String key) async {
    final token = SessionService.authToken;
    if (token == null || token.isEmpty) {
      return PageContentSnapshot(
        key: key,
        data: mergePageData(key, null),
        version: 0,
      );
    }
    final path = SessionService.isAdmin
        ? '/api/admin/page-content/$key'
        : '/api/mobile/page-content/$key';
    final response = await http
        .get(
          Uri.parse('${AppConfig.apiBaseUrl}$path'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 12));
    return _parse(key, response);
  }

  PageContentSnapshot _storeResponse(String key, http.Response response) {
    final parsed = _parse(key, response);
    _memory[key] = parsed;
    unawaited(_writeDisk(parsed));
    _bump();
    return parsed;
  }

  PageContentSnapshot _parse(String key, http.Response response) {
    final body = _decode(response.body);
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load page content');
    }
    final raw = body['data'] as Map<String, dynamic>? ?? {};
    final data = raw['data'] is Map
        ? Map<String, dynamic>.from(raw['data'] as Map)
        : raw;
    return PageContentSnapshot(
      key: key,
      data: mergePageData(key, data),
      version: int.tryParse('${raw['version'] ?? 1}') ?? 1,
    );
  }

  Future<Directory> _dir() async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}/page_content');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<PageContentSnapshot?> _readDisk(String key) async {
    try {
      final file = File('${(await _dir()).path}/$key.json');
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return null;
      return PageContentSnapshot(
        key: key,
        data: mergePageData(key, decoded['data'] as Map<String, dynamic>?),
        version: int.tryParse('${decoded['version'] ?? 0}') ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeDisk(PageContentSnapshot snapshot) async {
    try {
      final file = File('${(await _dir()).path}/${snapshot.key}.json');
      await file.writeAsString(
        jsonEncode({
          'version': snapshot.version,
          'data': snapshot.data,
        }),
      );
    } catch (_) {}
  }

  MediaType _imageContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return MediaType('image', 'heic');
    }
    if (lower.endsWith('.bmp')) return MediaType('image', 'bmp');
    return MediaType('image', 'jpeg');
  }

  Map<String, dynamic> _decode(String body) {
    if (body.isEmpty) return {};
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }
}

