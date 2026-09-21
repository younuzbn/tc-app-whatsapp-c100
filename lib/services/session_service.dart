import 'dart:async';

import 'package:flutter/services.dart';

class SessionService {
  static const _channel = MethodChannel('win_app/session');

  static String? authToken;
  static String? username;
  static String? displayPhoneNumber;
  static String? userId;
  static String? role;
  static String? referralCode;
  static bool isAdmin = false;
  static bool phoneVerified = false;
  static String? lastPhoneNumber;
  static String? pendingReferralCode;

  static bool get isLoggedIn => authToken != null && authToken!.isNotEmpty;

  static String? tenDigitPhone(String? raw) {
    final digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return null;
    return digits.substring(digits.length - 10);
  }

  static void setSession({
    required String token,
    required String sessionUsername,
    required String sessionDisplayPhoneNumber,
    String? sessionUserId,
    String? sessionRole,
    String? sessionReferralCode,
    bool sessionIsAdmin = false,
    bool sessionPhoneVerified = false,
  }) {
    authToken = token;
    username = sessionUsername;
    displayPhoneNumber = sessionDisplayPhoneNumber;
    userId = sessionUserId;
    role = sessionRole;
    referralCode = sessionReferralCode;
    isAdmin = sessionIsAdmin;
    phoneVerified = sessionPhoneVerified;
    unawaited(_persist());
    unawaited(
      rememberLastPhone(
        tenDigitPhone(sessionDisplayPhoneNumber) ??
            tenDigitPhone(sessionUsername) ??
            '',
      ),
    );
  }

  static void clear() {
    authToken = null;
    username = null;
    displayPhoneNumber = null;
    userId = null;
    role = null;
    referralCode = null;
    isAdmin = false;
    phoneVerified = false;
    unawaited(_persist());
  }

  static Future<void> rememberLastPhone(String phone) async {
    final digits = tenDigitPhone(phone);
    if (digits == null) return;
    lastPhoneNumber = digits;
    try {
      await _channel.invokeMethod<void>('saveLastPhone', {'phone': digits});
    } catch (_) {
      // Native storage is unavailable (e.g. tests).
    }
  }

  static Future<void> rememberPendingReferral(String code) async {
    final value = code.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (value.isEmpty) return;
    pendingReferralCode = value;
    try {
      await _channel.invokeMethod<void>('savePendingReferral', {'code': value});
    } catch (_) {
      // Native storage is unavailable (e.g. tests).
    }
  }

  static void setPhoneVerified(bool value) {
    phoneVerified = value;
    unawaited(_persist());
  }

  static void markPhoneVerified() => setPhoneVerified(true);

  static Future<void> restore() async {
    try {
      final last = await _channel.invokeMethod<dynamic>('loadLastPhone');
      final digits = tenDigitPhone(last?.toString());
      if (digits != null) lastPhoneNumber = digits;
    } catch (_) {}
    try {
      final pending = await _channel.invokeMethod<dynamic>('loadPendingReferral');
      final code = pending?.toString().trim().toUpperCase() ?? '';
      if (code.isNotEmpty) pendingReferralCode = code;
    } catch (_) {}
    try {
      final raw = await _channel.invokeMethod<dynamic>('load');
      if (raw is! Map) return;
      final data = raw.map((key, value) => MapEntry(key.toString(), value));
      final token = data['authToken']?.toString() ?? '';
      if (token.isEmpty) return;
      authToken = token;
      username = data['username']?.toString();
      displayPhoneNumber = data['displayPhoneNumber']?.toString();
      userId = data['userId']?.toString();
      role = data['role']?.toString();
      referralCode = data['referralCode']?.toString();
      isAdmin = data['isAdmin'] == true || data['isAdmin']?.toString() == 'true';
      phoneVerified =
          data['phoneVerified'] == true ||
          data['phoneVerified']?.toString() == 'true';
      lastPhoneNumber =
          tenDigitPhone(displayPhoneNumber) ??
          tenDigitPhone(username) ??
          lastPhoneNumber;
    } catch (_) {
      // Stay logged out if native session storage is unavailable.
    }
  }

  static Future<void> _persist() async {
    final payload = isLoggedIn
        ? <String, dynamic>{
            'authToken': authToken,
            'username': username,
            'displayPhoneNumber': displayPhoneNumber,
            'userId': userId,
            'role': role,
            'referralCode': referralCode,
            'isAdmin': isAdmin,
            'phoneVerified': phoneVerified,
          }
        : <String, dynamic>{};
    try {
      await _channel.invokeMethod<void>('save', payload);
    } catch (_) {
      // Native storage is unavailable (e.g. tests).
    }
  }
}
