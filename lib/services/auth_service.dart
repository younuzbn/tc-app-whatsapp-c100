import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'session_service.dart';

class PhoneCheckResult {
  const PhoneCheckResult({
    required this.exists,
    required this.isAdminNumber,
    this.referralValid,
  });

  final bool exists;
  final bool isAdminNumber;
  final bool? referralValid;
}

class MobileAuthResult {
  const MobileAuthResult({
    required this.displayPhoneNumber,
    required this.username,
    required this.token,
    required this.userId,
    required this.isAdmin,
    this.role,
    this.referralCode,
    this.name,
  });

  final String displayPhoneNumber;
  final String username;
  final String token;
  final String userId;
  final bool isAdmin;
  final String? role;
  final String? referralCode;
  final String? name;
}

class MobileProfile {
  const MobileProfile({
    required this.name,
    required this.displayPhoneNumber,
    required this.phoneNumber,
    required this.referralCode,
    required this.memberSince,
    required this.isActive,
    required this.entryBalance,
    required this.totalWinnings,
    required this.referralEarned,
    required this.inviteCount,
  });

  final String name;
  final String displayPhoneNumber;
  final String phoneNumber;
  final String referralCode;
  final DateTime? memberSince;
  final bool isActive;
  final double entryBalance;
  final double totalWinnings;
  final double referralEarned;
  final int inviteCount;
}

class AuthService {
  const AuthService();

  Future<PhoneCheckResult> checkPhone({
    required String countryCode,
    required String phoneNumber,
    String? referralCode,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/mobile/check-phone'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'countryCode': countryCode,
              'phoneNumber': phoneNumber,
              if (referralCode != null && referralCode.isNotEmpty)
                'referralCode': referralCode,
            }),
          )
          .timeout(const Duration(seconds: 8));

      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to check phone number');
      }

      final data = body['data'] as Map<String, dynamic>? ?? {};
      return PhoneCheckResult(
        exists: data['exists'] == true,
        isAdminNumber: data['isAdminNumber'] == true,
        referralValid: data['referralValid'] is bool
            ? data['referralValid'] as bool
            : null,
      );
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }
  }

  Future<MobileAuthResult> register({
    required String countryCode,
    required String phoneNumber,
    required String password,
    required String referralCode,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/mobile/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'countryCode': countryCode,
              'phoneNumber': phoneNumber,
              'password': password,
              'referralCode': referralCode,
            }),
          )
          .timeout(const Duration(seconds: 12));

      return _parseAuthResponse(response, countryCode, phoneNumber);
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }
  }

  Future<MobileAuthResult> loginWithPassword({
    required String countryCode,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/mobile/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'countryCode': countryCode,
              'phoneNumber': phoneNumber,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 12));

      return _parseAuthResponse(response, countryCode, phoneNumber);
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }
  }

  Future<String?> fetchMyReferralCode() async {
    final profile = await fetchProfile();
    return profile?.referralCode ?? SessionService.referralCode;
  }

  Future<MobileProfile?> fetchProfile() async {
    final token = SessionService.authToken;
    if (token == null || token.isEmpty || SessionService.isAdmin) {
      return null;
    }
    try {
      final response = await http
          .get(
            Uri.parse('${AppConfig.apiBaseUrl}/api/mobile/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 8));
      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        return null;
      }
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final code = data['referralCode']?.toString();
      if (code != null && code.isNotEmpty) {
        SessionService.referralCode = code;
      }
      final wallet = data['wallet'] as Map<String, dynamic>? ?? {};
      final referral = data['referral'] as Map<String, dynamic>? ?? {};
      return MobileProfile(
        name: data['name']?.toString() ?? '',
        displayPhoneNumber:
            data['displayPhoneNumber']?.toString() ??
            SessionService.displayPhoneNumber ??
            '',
        phoneNumber: data['phoneNumber']?.toString() ?? '',
        referralCode: code ?? SessionService.referralCode ?? '',
        memberSince: DateTime.tryParse(data['memberSince']?.toString() ?? ''),
        isActive: data['isActive'] != false,
        entryBalance:
            double.tryParse(wallet['available']?.toString() ?? '') ?? 0,
        totalWinnings:
            double.tryParse(wallet['winningsBalance']?.toString() ?? '') ?? 0,
        referralEarned:
            double.tryParse(referral['referralEarned']?.toString() ?? '') ?? 0,
        inviteCount: int.tryParse(referral['inviteCount']?.toString() ?? '') ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> updateProfile({required String name}) async {
    final token = SessionService.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Login required');
    }
    final response = await http
        .put(
          Uri.parse('${AppConfig.apiBaseUrl}/api/mobile/profile'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'name': name}),
        )
        .timeout(const Duration(seconds: 8));
    final body = _decodeBody(response.body);
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to update profile');
    }
  }

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

      return _parseAuthResponse(response, countryCode, phoneNumber);
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }
  }

  MobileAuthResult _parseAuthResponse(
    http.Response response,
    String countryCode,
    String phoneNumber,
  ) {
    final body = _decodeBody(response.body);
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Authentication failed');
    }

    final data = body['data'] as Map<String, dynamic>? ?? {};
    final user = data['user'] as Map<String, dynamic>? ?? {};
    final token = data['token']?.toString() ?? '';
    final username = user['username']?.toString() ?? '$countryCode$phoneNumber';
    final userId = user['id']?.toString() ?? username;
    final isAdmin = user['isAdmin'] == true;
    final role = user['role']?.toString();
    final referralCode = user['referralCode']?.toString();
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
      sessionReferralCode: referralCode,
      sessionIsAdmin: isAdmin,
    );

    return MobileAuthResult(
      displayPhoneNumber: displayPhoneNumber,
      username: username,
      token: token,
      userId: userId,
      isAdmin: isAdmin,
      role: role,
      referralCode: referralCode,
    );
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
