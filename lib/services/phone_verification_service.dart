import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class PhoneVerificationService {
  String? _verificationId;
  int? _resendToken;

  FirebaseAuth? get _auth {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  bool get isReady => _auth != null;

  String e164({String countryCode = '91', required String phoneNumber}) {
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final last10 = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
    final cc = countryCode.replaceAll(RegExp(r'\D'), '');
    return '+$cc$last10';
  }

  Future<void> sendOtp({
    required String countryCode,
    required String phoneNumber,
    required void Function(String message) onFailed,
    required void Function() onCodeSent,
    Future<void> Function(String? smsCode)? onAutoVerified,
  }) async {
    final auth = _auth;
    if (auth == null) {
      onFailed('Phone verification is not set up yet. Add Firebase config and rebuild.');
      return;
    }
    final number = e164(countryCode: countryCode, phoneNumber: phoneNumber);
    debugPrint('[PhoneVerify] sendOtp number=$number resendToken=$_resendToken');
    try {
      await auth.verifyPhoneNumber(
        phoneNumber: number,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (credential) async {
          debugPrint(
            '[PhoneVerify] verificationCompleted smsLen=${credential.smsCode?.length ?? 0}',
          );
          try {
            await auth.signInWithCredential(credential);
            if (onAutoVerified != null) {
              await onAutoVerified(credential.smsCode);
            }
          } catch (error) {
            debugPrint('[PhoneVerify] auto-verify failed: $error');
            onFailed(_mapError(error));
          }
        },
        verificationFailed: (error) {
          debugPrint(
            '[PhoneVerify] verificationFailed code=${error.code} message=${error.message}',
          );
          onFailed(_mapError(error));
        },
        codeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          debugPrint(
            '[PhoneVerify] codeSent idLen=${verificationId.length} resendToken=$resendToken',
          );
          onCodeSent();
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
          debugPrint(
            '[PhoneVerify] codeAutoRetrievalTimeout idLen=${verificationId.length}',
          );
        },
      );
    } catch (error) {
      onFailed(_mapError(error));
    }
  }

  Future<String> confirmSmsCode(String smsCode) async {
    final auth = _auth;
    final verificationId = _verificationId;
    if (auth == null) {
      throw Exception('Phone verification is not set up yet.');
    }
    if (verificationId == null || verificationId.isEmpty) {
      throw Exception('Request an OTP first');
    }
    final digits = smsCode.replaceAll(RegExp(r'\D'), '');
    debugPrint(
      '[PhoneVerify] confirmSmsCode raw="$smsCode" '
      'units=${smsCode.codeUnits} digits="$digits" '
      'idLen=${verificationId.length}',
    );
    if (digits.length < 6) {
      debugPrint('[PhoneVerify] confirm rejected digits="$digits" raw="$smsCode"');
      throw Exception('Enter the 6-digit OTP');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: digits.substring(0, 6),
    );
    await auth.signInWithCredential(credential);
    return idToken();
  }

  Future<String> idToken() async {
    final user = _auth?.currentUser;
    if (user == null) {
      throw Exception('Could not confirm OTP. Try again.');
    }
    try {
      await user.reload();
    } catch (error) {
      debugPrint('[PhoneVerify] user.reload failed: $error');
    }
    var token = await user.getIdToken(true);
    var phone = phoneTailFromIdToken(token);
    debugPrint(
      '[PhoneVerify] idToken len=${token?.length ?? 0} '
      'phoneTail=$phone userPhone=${user.phoneNumber}',
    );
    if (token != null && token.isNotEmpty && (phone == null || phone.length != 10)) {
      try {
        await user.reload();
      } catch (error) {
        debugPrint('[PhoneVerify] user.reload retry failed: $error');
      }
      token = await user.getIdToken(true);
      phone = phoneTailFromIdToken(token);
      debugPrint(
        '[PhoneVerify] idToken refreshed len=${token?.length ?? 0} phoneTail=$phone',
      );
    }
    if (token == null || token.isEmpty) {
      throw Exception('Could not confirm OTP. Try again.');
    }
    return token;
  }

  /// Last 10 digits of the phone claim inside a Firebase ID token.
  static String? phoneTailFromIdToken(String? token) {
    if (token == null || token.isEmpty) return null;
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;
      final identities = decoded['firebase'];
      String? raw = decoded['phone_number']?.toString();
      if ((raw == null || raw.isEmpty) && identities is Map) {
        final phones = identities['identities'];
        if (phones is Map && phones['phone'] is List && (phones['phone'] as List).isNotEmpty) {
          raw = phones['phone'].first?.toString();
        }
      }
      final digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
      if (digits.length < 10) return digits.isEmpty ? null : digits;
      return digits.substring(digits.length - 10);
    } catch (error) {
      debugPrint('[PhoneVerify] token decode failed: $error');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (_) {}
  }

  String _mapError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-phone-number':
          return 'Invalid mobile number';
        case 'too-many-requests':
          return 'Too many OTP attempts. Try again later.';
        case 'quota-exceeded':
          return 'SMS limit reached. Try again later.';
        case 'invalid-verification-code':
          return 'Wrong OTP. Please try again.';
        case 'session-expired':
          return 'OTP expired. Request a new one.';
        case 'missing-client-identifier':
        case 'app-not-authorized':
          return 'Firebase Android app SHA keys are missing. Add debug SHA-1 in Firebase.';
        default:
          return error.message?.isNotEmpty == true
              ? error.message!
              : 'Could not send OTP. Please try again.';
      }
    }
    return error.toString().replaceFirst('Exception: ', '');
  }
}
