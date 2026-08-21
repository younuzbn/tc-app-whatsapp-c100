import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'session_service.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
    this.timeSlot,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final bool read;
  final DateTime? createdAt;
  final String? timeSlot;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'];
    String? timeSlot;
    if (payload is Map) {
      timeSlot = payload['timeSlot']?.toString();
    }
    return AppNotification(
      id: json['_id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      read: json['read'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      timeSlot: timeSlot,
    );
  }
}

class NotificationService {
  const NotificationService();

  Future<({List<AppNotification> items, int unread})> list() async {
    final token = SessionService.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Login required');
    }
    try {
      final response = await http
          .get(
            Uri.parse('${AppConfig.apiBaseUrl}/api/mobile/notifications?limit=50'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 8));
      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to load notifications');
      }
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final items = (data['notifications'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList();
      final unread = int.tryParse(data['unread']?.toString() ?? '') ??
          items.where((n) => !n.read).length;
      return (items: items, unread: unread);
    } on SocketException {
      throw Exception(_serverUnavailable());
    } on HttpException {
      throw Exception(_serverUnavailable());
    } on TimeoutException {
      throw Exception(_serverUnavailable());
    }
  }

  Future<int> unreadCount() async {
    final token = SessionService.authToken;
    if (token == null || token.isEmpty) return 0;
    try {
      final response = await http
          .get(
            Uri.parse('${AppConfig.apiBaseUrl}/api/mobile/notifications/unread'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 8));
      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) return 0;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return int.tryParse(data['unread']?.toString() ?? '') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markAllRead() async {
    final token = SessionService.authToken;
    if (token == null || token.isEmpty) return;
    await http
        .put(
          Uri.parse('${AppConfig.apiBaseUrl}/api/mobile/notifications/read-all'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
  }

  Future<void> markRead(String id) async {
    final token = SessionService.authToken;
    if (token == null || token.isEmpty || id.isEmpty) return;
    await http
        .put(
          Uri.parse('${AppConfig.apiBaseUrl}/api/mobile/notifications/$id/read'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> _decodeBody(String body) {
    if (body.isEmpty) return {};
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  String _serverUnavailable() =>
      'Server on ${AppConfig.apiBaseUrl} is not reachable right now.';
}
