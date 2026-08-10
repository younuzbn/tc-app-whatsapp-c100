import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'session_service.dart';

class AdminReferralCodeItem {
  const AdminReferralCodeItem({
    required this.id,
    required this.code,
    required this.label,
    required this.isActive,
    required this.joinedCount,
  });

  final String id;
  final String code;
  final String label;
  final bool isActive;
  final int joinedCount;

  factory AdminReferralCodeItem.fromJson(Map<String, dynamic> json) {
    return AdminReferralCodeItem(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      isActive: json['isActive'] != false,
      joinedCount: int.tryParse(json['joinedCount']?.toString() ?? '') ?? 0,
    );
  }
}

class ReferralTreeUser {
  const ReferralTreeUser({
    required this.id,
    required this.username,
    required this.displayPhoneNumber,
    required this.referralCode,
    required this.childCount,
  });

  final String id;
  final String username;
  final String displayPhoneNumber;
  final String referralCode;
  final int childCount;

  factory ReferralTreeUser.fromJson(Map<String, dynamic> json) {
    return ReferralTreeUser(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      displayPhoneNumber: json['displayPhoneNumber']?.toString() ??
          json['username']?.toString() ??
          '',
      referralCode: json['referralCode']?.toString() ?? '',
      childCount: int.tryParse(json['childCount']?.toString() ?? '') ?? 0,
    );
  }
}

class ReferralTreeNode {
  const ReferralTreeNode({
    required this.type,
    required this.code,
    required this.label,
    required this.joinedCount,
    required this.users,
    this.ownerDisplay,
  });

  final String type;
  final String code;
  final String label;
  final int joinedCount;
  final List<ReferralTreeUser> users;
  final String? ownerDisplay;

  factory ReferralTreeNode.fromJson(Map<String, dynamic> json) {
    final usersJson = json['users'] as List<dynamic>? ?? const [];
    final owner = json['owner'] as Map<String, dynamic>?;
    return ReferralTreeNode(
      type: json['type']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      joinedCount: int.tryParse(json['joinedCount']?.toString() ?? '') ?? 0,
      users: usersJson
          .whereType<Map<String, dynamic>>()
          .map(ReferralTreeUser.fromJson)
          .toList(),
      ownerDisplay: owner?['displayPhoneNumber']?.toString() ??
          owner?['username']?.toString(),
    );
  }
}

class ReferralService {
  const ReferralService();

  Future<List<AdminReferralCodeItem>> listCodes() async {
    final body = await _request('/api/admin/referral-codes');
    final data = body['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(AdminReferralCodeItem.fromJson)
        .toList();
  }

  Future<AdminReferralCodeItem> createCode({String? code, String? label}) async {
    final body = await _request(
      '/api/admin/referral-codes',
      method: 'POST',
      requestBody: {
        if (code != null && code.trim().isNotEmpty) 'code': code.trim(),
        if (label != null && label.trim().isNotEmpty) 'label': label.trim(),
      },
    );
    final data = body['data'] as Map<String, dynamic>? ?? {};
    return AdminReferralCodeItem.fromJson(data);
  }

  Future<List<ReferralTreeNode>> getTreeRoot() async {
    final body = await _request('/api/admin/referral-tree');
    final data = body['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ReferralTreeNode.fromJson)
        .toList();
  }

  Future<ReferralTreeNode> getTreeByCode(String referralCode) async {
    final encoded = Uri.encodeComponent(referralCode);
    final body = await _request('/api/admin/referral-tree/$encoded');
    final data = body['data'] as Map<String, dynamic>? ?? {};
    return ReferralTreeNode.fromJson(data);
  }

  Future<Map<String, dynamic>> _request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? requestBody,
  }) async {
    final token = SessionService.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Login required');
    }

    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    http.Response response;
    try {
      if (method == 'POST') {
        response = await http
            .post(
              uri,
              headers: _headers(token),
              body: jsonEncode(requestBody ?? {}),
            )
            .timeout(const Duration(seconds: 10));
      } else {
        response = await http
            .get(uri, headers: _headers(token))
            .timeout(const Duration(seconds: 10));
      }
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }

    final body = _decodeBody(response.body);
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Request failed');
    }
    return body;
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

  String _serverUnavailableMessage() {
    return 'Server on ${AppConfig.apiBaseUrl} is not reachable right now.';
  }
}
