import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

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
    Future<void> Function()? onAutoVerified,
  }) async {
    final auth = _auth;
    if (auth == null) {
      onFailed('Phone verification is not set up yet. Add Firebase config and rebuild.');
      return;
    }
    final number = e164(countryCode: countryCode, phoneNumber: phoneNumber);
    try {
      await auth.verifyPhoneNumber(
        phoneNumber: number,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (credential) async {
          try {
            await auth.signInWithCredential(credential);
            if (onAutoVerified != null) await onAutoVerified();
          } catch (error) {
            onFailed(_mapError(error));
          }
        },
        verificationFailed: (error) => onFailed(_mapError(error)),
        codeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent();
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
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
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    await auth.signInWithCredential(credential);
    return idToken();
  }

  Future<String> idToken() async {
    final user = _auth?.currentUser;
    final token = await user?.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw Exception('Could not confirm OTP. Try again.');
    }
    return token;
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
