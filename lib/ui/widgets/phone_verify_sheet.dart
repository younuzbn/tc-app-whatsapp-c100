import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../services/phone_verification_service.dart';
import '../../services/session_service.dart';
import '../theme/win_theme.dart';

Future<bool> showPhoneVerifyDialog(
  BuildContext context, {
  required String countryCode,
  required String phoneNumber,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PhoneVerifyDialog(
      countryCode: countryCode,
      phoneNumber: phoneNumber,
    ),
  );
  return result == true;
}

class _PhoneVerifyDialog extends StatefulWidget {
  const _PhoneVerifyDialog({
    required this.countryCode,
    required this.phoneNumber,
  });

  final String countryCode;
  final String phoneNumber;

  @override
  State<_PhoneVerifyDialog> createState() => _PhoneVerifyDialogState();
}

class _PhoneVerifyDialogState extends State<_PhoneVerifyDialog> {
  final _auth = const AuthService();
  final _firebase = PhoneVerificationService();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocus = List.generate(6, (_) => FocusNode());

  bool _sending = false;
  bool _verifying = false;
  bool _codeSent = false;
  String? _error;
  int _resendIn = 0;
  Timer? _timer;

  String get _digits {
    final raw = widget.phoneNumber.replaceAll(RegExp(r'\D'), '');
    return raw.length >= 10 ? raw.substring(raw.length - 10) : raw;
  }

  String get _display => '+${widget.countryCode} $_digits';

  String get _otp => _otpControllers.map((c) => c.text).join();

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocus) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendIn = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendIn <= 1) {
        timer.cancel();
        setState(() => _resendIn = 0);
      } else {
        setState(() => _resendIn -= 1);
      }
    });
  }

  Future<void> _sendOtp() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    await _firebase.sendOtp(
      countryCode: widget.countryCode,
      phoneNumber: _digits,
      onFailed: (message) {
        if (!mounted) return;
        setState(() {
          _sending = false;
          _error = message;
        });
      },
      onCodeSent: () {
        if (!mounted) return;
        setState(() {
          _sending = false;
          _codeSent = true;
          _error = null;
        });
        _startResendTimer();
      },
      onAutoVerified: _submitFirebaseToken,
    );
  }

  Future<void> _verifyTypedOtp() async {
    if (_verifying) return;
    if (_otp.length != 6) {
      setState(() => _error = 'Enter the 6-digit OTP');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final token = await _firebase.confirmSmsCode(_otp);
      await _finish(token);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _submitFirebaseToken() async {
    try {
      final token = await _firebase.idToken();
      await _finish(token);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _verifying = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _finish(String idToken) async {
    try {
      await _auth.confirmPhoneVerification(idToken);
      await _firebase.signOut();
      SessionService.markPhoneVerified();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      await _firebase.signOut();
      if (!mounted) return;
      setState(() {
        _sending = false;
        _verifying = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _otpFocus[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocus[index - 1].requestFocus();
    }
    if (_otp.length == 6) {
      unawaited(_verifyTypedOtp());
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final busy = _sending || _verifying;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              color: const Color(0xF0101820),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0x554ADE80)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Verify mobile number',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We will send an OTP to $_display',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: WinTheme.muted, height: 1.4),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
                if (_codeSent) ...[
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 38,
                        height: 48,
                        child: TextField(
                          controller: _otpControllers[index],
                          focusNode: _otpFocus[index],
                          enabled: !busy,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                          cursorColor: WinTheme.green,
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: const Color(0x33101820),
                            contentPadding: EdgeInsets.zero,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0x554ADE80),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: WinTheme.green,
                              ),
                            ),
                          ),
                          onChanged: (value) => _onOtpChanged(index, value),
                        ),
                      );
                    }),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: busy
                      ? null
                      : _codeSent
                          ? _verifyTypedOtp
                          : _sendOtp,
                  style: FilledButton.styleFrom(
                    backgroundColor: WinTheme.green,
                    foregroundColor: const Color(0xFF052E16),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _codeSent ? 'Verify OTP' : 'Send OTP',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
                if (_codeSent) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: busy || _resendIn > 0 ? null : _sendOtp,
                    child: Text(
                      _resendIn > 0
                          ? 'Resend OTP in $_resendIn s'
                          : 'Resend OTP',
                      style: const TextStyle(color: WinTheme.green),
                    ),
                  ),
                ],
                TextButton(
                  onPressed: busy ? null : () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: WinTheme.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
