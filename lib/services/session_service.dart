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
  static bool notificationPageOpened = false;
  static final Set<String> seenNotificationIds = {};

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
    if (sessionUserId != userId) {
      notificationPageOpened = false;
      seenNotificationIds.clear();
    }
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

  static void replaceToken(String token) {
    final next = token.trim();
    if (next.isEmpty || next == authToken) return;
    authToken = next;
    unawaited(_persist());
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
    notificationPageOpened = false;
    seenNotificationIds.clear();
    unawaited(_persist());
    unawaited(_setAppBadge(0));
  }

  static Future<void> _setAppBadge(int count) async {
    try {
      await _channel.invokeMethod<void>('setAppBadge', {
        'count': count,
        'title': '',
        'text': '',
        'alert': false,
      });
    } catch (_) {}
  }

  /// Opening the notifications screen clears the home-header count.
  /// Green dots stay until the user marks notifications read.
  static void acknowledgeNotifications(Iterable<String> ids) {
    notificationPageOpened = true;
    for (final id in ids) {
      if (id.isNotEmpty) seenNotificationIds.add(id);
    }
    if (seenNotificationIds.length > 300) {
      final extra = seenNotificationIds.length - 300;
      seenNotificationIds.removeAll(seenNotificationIds.take(extra).toList());
    }
    unawaited(_persist());
  }

  static int notificationBadgeCount({
    required Iterable<({String id, bool read})> items,
    required int serverUnread,
  }) {
    if (!notificationPageOpened) return serverUnread;
    return items
        .where((item) => !item.read && !seenNotificationIds.contains(item.id))
        .length;
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
      notificationPageOpened =
          data['notificationPageOpened'] == true ||
          data['notificationPageOpened']?.toString() == 'true';
      seenNotificationIds
        ..clear()
        ..addAll(
          (data['seenNotificationIds']?.toString() ?? '')
              .split(',')
              .where((id) => id.isNotEmpty),
        );
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
            'notificationPageOpened': notificationPageOpened,
            'seenNotificationIds': seenNotificationIds.join(','),
          }
        : <String, dynamic>{};
    try {
      await _channel.invokeMethod<void>('save', payload);
    } catch (_) {
      // Native storage is unavailable (e.g. tests).
    }
  }
}
