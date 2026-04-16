import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'session_service.dart';

class MobileAuthResult {
  const MobileAuthResult({
    required this.displayPhoneNumber,
    required this.username,
    required this.token,
    required this.userId,
    required this.isAdmin,
    this.role,
  });

  final String displayPhoneNumber;
  final String username;
  final String token;
  final String userId;
  final bool isAdmin;
  final String? role;
}

class AuthService {
  const AuthService();

  Future<void> requestOtp({
    required String countryCode,
    required String phoneNumber,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/mobile/request-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'countryCode': countryCode,
              'phoneNumber': phoneNumber,
            }),
          )
          .timeout(const Duration(seconds: 8));

      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to request OTP');
      }
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }
  }

  Future<MobileAuthResult> verifyOtp({
    required String countryCode,
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/mobile/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'countryCode': countryCode,
              'phoneNumber': phoneNumber,
              'otp': otp,
            }),
          )
          .timeout(const Duration(seconds: 8));

      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to verify OTP');
      }

      final data = body['data'] as Map<String, dynamic>? ?? {};
      final user = data['user'] as Map<String, dynamic>? ?? {};
      final token = data['token']?.toString() ?? '';
      final username = user['username']?.toString() ?? '$countryCode$phoneNumber';
      final userId = user['id']?.toString() ?? username;
      final isAdmin = user['isAdmin'] == true;
      final role = user['role']?.toString();
      final displayPhoneNumber =
          (user['displayPhoneNumber'] as String?) ?? '+$countryCode $phoneNumber';

      if (token.isEmpty) {
        throw Exception('Missing login token');
      }

      SessionService.setSession(
        token: token,
        sessionUsername: username,
        sessionDisplayPhoneNumber: displayPhoneNumber,
        sessionUserId: userId,
        sessionRole: role,
        sessionIsAdmin: isAdmin,
      );

      return MobileAuthResult(
        displayPhoneNumber: displayPhoneNumber,
        username: username,
        token: token,
        userId: userId,
        isAdmin: isAdmin,
        role: role,
      );
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      return {
        'success': false,
        'message':
            'Server returned an invalid response. Please verify API URL/proxy.',
      };
    }

    return {};
  }

  String _serverUnavailableMessage() {
    return 'Server on ${AppConfig.apiBaseUrl} is not reachable right now.';
  }
}
