import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_http.dart';
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
    this.profileImageUrl,
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
  final String? profileImageUrl;
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
            headers: jsonHeaders(),
            body: jsonEncode({
              'countryCode': countryCode,
              'phoneNumber': phoneNumber,
              if (referralCode != null && referralCode.isNotEmpty)
                'referralCode': referralCode,
            }),
          )
          .timeout(apiTimeout);

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
    } catch (error) {
      if (isNetworkError(error)) throw mapNetworkError(error);
      rethrow;
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
            headers: jsonHeaders(),
            body: jsonEncode({
              'countryCode': countryCode,
              'phoneNumber': phoneNumber,
              'password': password,
              'referralCode': referralCode,
            }),
          )
          .timeout(apiTimeout);

      return _parseAuthResponse(response, countryCode, phoneNumber);
    } catch (error) {
      if (isNetworkError(error)) throw mapNetworkError(error);
      rethrow;
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
            headers: jsonHeaders(),
            body: jsonEncode({
              'countryCode': countryCode,
              'phoneNumber': phoneNumber,
              'password': password,
            }),
          )
          .timeout(apiTimeout);

      return _parseAuthResponse(response, countryCode, phoneNumber);
    } catch (error) {
      if (isNetworkError(error)) throw mapNetworkError(error);
      rethrow;
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
      final imagePath = data['profileImageUrl']?.toString() ?? '';
      final imageUrl = imagePath.isEmpty
          ? null
          : imagePath.startsWith('http')
          ? imagePath
          : '${AppConfig.apiBaseUrl}$imagePath';
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
        profileImageUrl: imageUrl,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> updateProfile({
    String? name,
    String? imageBase64,
    String? imageMime,
  }) async {
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
          body: jsonEncode({
            if (name != null) 'name': name,
            if (imageBase64 != null && imageBase64.isNotEmpty)
              'imageBase64': imageBase64,
            if (imageMime != null && imageMime.isNotEmpty) 'imageMime': imageMime,
          }),
        )
        .timeout(const Duration(seconds: 30));
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
            headers: jsonHeaders(),
            body: jsonEncode({
              'countryCode': countryCode,
              'phoneNumber': phoneNumber,
            }),
          )
          .timeout(apiTimeout);

      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to request OTP');
      }
    } catch (error) {
      if (isNetworkError(error)) throw mapNetworkError(error);
      rethrow;
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
            headers: jsonHeaders(),
            body: jsonEncode({
              'countryCode': countryCode,
              'phoneNumber': phoneNumber,
              'otp': otp,
            }),
          )
          .timeout(apiTimeout);

      return _parseAuthResponse(response, countryCode, phoneNumber);
    } catch (error) {
      if (isNetworkError(error)) throw mapNetworkError(error);
      rethrow;
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
}
