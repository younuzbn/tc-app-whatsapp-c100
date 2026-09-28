import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_http.dart';
import 'session_service.dart';

class ComplaintMessageItem {
  const ComplaintMessageItem({
    required this.id,
    required this.userId,
    required this.userPhone,
    required this.userName,
    required this.senderRole,
    required this.senderId,
    required this.text,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
    required this.readByAdmin,
    required this.readByUser,
  });

  final String id;
  final String userId;
  final String userPhone;
  final String userName;
  final String senderRole;
  final String senderId;
  final String text;
  final String mediaUrl;
  final String mediaType;
  final DateTime createdAt;
  final bool readByAdmin;
  final bool readByUser;

  bool get isFromUser => senderRole == 'user';
  bool get isFromAdmin => senderRole == 'admin';
  bool get hasMedia => mediaUrl.isNotEmpty && mediaType != 'none';

  factory ComplaintMessageItem.fromJson(Map<String, dynamic> json) {
    final mediaPath = json['mediaUrl']?.toString() ?? '';
    final fullUrl = mediaPath.isEmpty
        ? ''
        : mediaPath.startsWith('http')
            ? mediaPath
            : '${AppConfig.apiBaseUrl}$mediaPath';

    return ComplaintMessageItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userPhone: json['userPhone']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      senderRole: json['senderRole']?.toString() ?? 'user',
      senderId: json['senderId']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      mediaUrl: fullUrl,
      mediaType: json['mediaType']?.toString() ?? 'none',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      readByAdmin: json['readByAdmin'] == true,
      readByUser: json['readByUser'] == true,
    );
  }
}

class ComplaintThreadItem {
  const ComplaintThreadItem({
    required this.userId,
    required this.userPhone,
    required this.userName,
    required this.lastMessage,
    required this.lastMediaType,
    required this.lastSenderRole,
    required this.lastMessageTime,
    required this.unreadCount,
  });

  final String userId;
  final String userPhone;
  final String userName;
  final String lastMessage;
  final String lastMediaType;
  final String lastSenderRole;
  final DateTime lastMessageTime;
  final int unreadCount;

  factory ComplaintThreadItem.fromJson(Map<String, dynamic> json) {
    return ComplaintThreadItem(
      userId: json['_id']?.toString() ?? '',
      userPhone: json['userPhone']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      lastMessage: json['lastMessage']?.toString() ?? '',
      lastMediaType: json['lastMediaType']?.toString() ?? 'none',
      lastSenderRole: json['lastSenderRole']?.toString() ?? 'user',
      lastMessageTime:
          DateTime.tryParse(json['lastMessageTime']?.toString() ?? '') ??
              DateTime.now(),
      unreadCount: int.tryParse(json['unreadCount']?.toString() ?? '0') ?? 0,
    );
  }
}

class SupportService {
  const SupportService();

  Map<String, String> _headers() {
    final token = SessionService.authToken ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Mobile user fetches their support/complaint messages
  Future<List<ComplaintMessageItem>> fetchUserMessages() async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppConfig.apiBaseUrl}/api/support/user/messages'),
            headers: _headers(),
          )
          .timeout(apiTimeout);

      final body = jsonDecode(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to load messages');
      }

      final list = body['data'] as List<dynamic>? ?? [];
      return list.map((e) => ComplaintMessageItem.fromJson(e)).toList();
    } catch (error) {
      if (isNetworkError(error)) throw mapNetworkError(error);
      rethrow;
    }
  }

  /// Mobile user sends a complaint message (text, image, or video)
  Future<ComplaintMessageItem> sendUserMessage({
    String? text,
    String? mediaPath,
    String? mediaType,
  }) async {
    try {
      String? mediaBase64;
      String? mimeType;

      if (mediaPath != null && mediaPath.isNotEmpty) {
        final file = File(mediaPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          mediaBase64 = base64Encode(bytes);
          final lower = mediaPath.toLowerCase();
          if (lower.endsWith('.png')) {
            mimeType = 'image/png';
          } else if (lower.endsWith('.webp')) {
            mimeType = 'image/webp';
          } else if (lower.endsWith('.mp4')) {
            mimeType = 'video/mp4';
          } else if (lower.endsWith('.mov')) {
            mimeType = 'video/quicktime';
          } else if (lower.endsWith('.3gp')) {
            mimeType = 'video/3gpp';
          } else if (mediaType == 'video') {
            mimeType = 'video/mp4';
          } else {
            mimeType = 'image/jpeg';
          }
        }
      }

      final response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/support/user/messages'),
            headers: _headers(),
            body: jsonEncode({
              if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
              if (mediaBase64 != null) 'mediaBase64': mediaBase64,
              if (mediaType != null) 'mediaType': mediaType,
              if (mimeType != null) 'mediaMime': mimeType,
            }),
          )
          .timeout(const Duration(seconds: 45));

      final body = jsonDecode(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to send message');
      }

      return ComplaintMessageItem.fromJson(body['data']);
    } catch (error) {
      if (isNetworkError(error)) throw mapNetworkError(error);
      rethrow;
    }
  }

  /// Admin fetches list of complaint threads
  Future<List<ComplaintThreadItem>> fetchAdminThreads() async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppConfig.apiBaseUrl}/api/support/admin/threads'),
            headers: _headers(),
          )
          .timeout(apiTimeout);

      final body = jsonDecode(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to load complaint threads');
      }

      final list = body['data'] as List<dynamic>? ?? [];
      return list.map((e) => ComplaintThreadItem.fromJson(e)).toList();
    } catch (error) {
      if (isNetworkError(error)) throw mapNetworkError(error);
      rethrow;
    }
  }

  /// Admin fetches total unread complaint messages count for notification badge
  Future<int> fetchAdminUnreadCount({DateTime? since}) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/support/admin/unread-count')
          .replace(
            queryParameters: since == null
                ? null
                : {'since': since.toUtc().toIso8601String()},
          );
      final response = await http
          .get(
            uri,
            headers: _headers(),
          )
          .timeout(const Duration(seconds: 8));

      final body = jsonDecode(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        return 0;
      }

      final data = body['data'] as Map<String, dynamic>? ?? {};
      return int.tryParse(data['unreadCount']?.toString() ?? '0') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Admin fetches messages for a specific user thread & marks read
  Future<List<ComplaintMessageItem>> fetchAdminUserMessages(String userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppConfig.apiBaseUrl}/api/support/admin/messages/$userId'),
            headers: _headers(),
          )
          .timeout(apiTimeout);

      final body = jsonDecode(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to load user messages');
      }

      final list = body['data'] as List<dynamic>? ?? [];
      return list.map((e) => ComplaintMessageItem.fromJson(e)).toList();
    } catch (error) {
      if (isNetworkError(error)) throw mapNetworkError(error);
      rethrow;
    }
  }

  /// Admin replies to a user complaint thread
  Future<ComplaintMessageItem> sendAdminMessage({
    required String userId,
    String? text,
    String? mediaPath,
    String? mediaType,
  }) async {
    try {
      String? mediaBase64;
      String? mimeType;

      if (mediaPath != null && mediaPath.isNotEmpty) {
        final file = File(mediaPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          mediaBase64 = base64Encode(bytes);
          final lower = mediaPath.toLowerCase();
          if (lower.endsWith('.png')) {
            mimeType = 'image/png';
          } else if (lower.endsWith('.webp')) {
            mimeType = 'image/webp';
          } else if (lower.endsWith('.mp4')) {
            mimeType = 'video/mp4';
          } else if (lower.endsWith('.mov')) {
            mimeType = 'video/quicktime';
          } else if (mediaType == 'video') {
            mimeType = 'video/mp4';
          } else {
            mimeType = 'image/jpeg';
          }
        }
      }

      final response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/support/admin/messages'),
            headers: _headers(),
            body: jsonEncode({
              'userId': userId,
              if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
              if (mediaBase64 != null) 'mediaBase64': mediaBase64,
              if (mediaType != null) 'mediaType': mediaType,
              if (mimeType != null) 'mediaMime': mimeType,
            }),
          )
          .timeout(const Duration(seconds: 45));

      final body = jsonDecode(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to send admin reply');
      }

      return ComplaintMessageItem.fromJson(body['data']);
    } catch (error) {
      if (isNetworkError(error)) throw mapNetworkError(error);
      rethrow;
    }
  }
}
