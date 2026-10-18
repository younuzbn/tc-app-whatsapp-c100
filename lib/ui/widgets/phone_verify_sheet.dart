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
  bool _verifyStarted = false;
  bool _applyingOtp = false;
  bool _codeSent = false;
  String? _error;
  String _storedOtp = '';
  String _lastBoxLog = '';
  final _committed = List.filled(6, '');
  late final List<VoidCallback> _focusListeners = List.generate(
    6,
    (index) => () => _onBoxFocus(index),
  );
  int _resendIn = 0;
  Timer? _timer;

  static const _marker = '\u200b';

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 6; i++) {
      _otpControllers[i].addListener(_onBoxTick);
      _otpFocus[i].addListener(_focusListeners[i]);
      final index = i;
      _otpFocus[i].onKeyEvent = (node, event) {
        if (event is! KeyDownEvent ||
            event.logicalKey != LogicalKeyboardKey.backspace) {
          return KeyEventResult.ignored;
        }
        if (_digitsOf(_otpControllers[index].text).isNotEmpty) {
          return KeyEventResult.ignored;
        }
        _deletePrevious(index);
        return KeyEventResult.handled;
      };
    }
  }

  void _onBoxTick() {
    if (_applyingOtp) return;
    final boxes = _boxTexts;
    final extracted = _extract(boxes);
    final signature = '$extracted|${boxes.join(',')}';
    if (signature == _lastBoxLog) return;
    _lastBoxLog = signature;
    _storedOtp = extracted;
    _log(
      'boxes ${boxes.map(_debugText).join(' | ')} extracted="$extracted"',
    );
  }

  String get _digits {
    final raw = widget.phoneNumber.replaceAll(RegExp(r'\D'), '');
    return raw.length >= 10 ? raw.substring(raw.length - 10) : raw;
  }

  String get _display => '+${widget.countryCode} $_digits';

  @override
  void dispose() {
    _timer?.cancel();
    for (var i = 0; i < 6; i++) {
      _otpControllers[i].removeListener(_onBoxTick);
      _otpControllers[i].dispose();
      _otpFocus[i].removeListener(_focusListeners[i]);
      _otpFocus[i].dispose();
    }
    super.dispose();
  }

  void _log(String message) {
    debugPrint('[PhoneVerify] $message');
  }

  String _debugText(String raw) {
    return '"$raw" len=${raw.length} units=${raw.codeUnits}';
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
    _log('send tapped phone=$_display stored="$_storedOtp"');
    _storedOtp = '';
    _clearBoxes();
    setState(() {
      _sending = true;
      _error = null;
    });
    await _firebase.sendOtp(
      countryCode: widget.countryCode,
      phoneNumber: _digits,
      onFailed: (message) {
        _log('send failed: $message');
        if (!mounted) return;
        setState(() {
          _sending = false;
          _error = message;
        });
      },
      onCodeSent: () {
        _log('ui codeSent mounted=$mounted');
        if (!mounted) return;
        setState(() {
          _sending = false;
          _codeSent = true;
          _error = null;
        });
        _startResendTimer();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _otpFocus.first.requestFocus();
        });
      },
      onAutoVerified: (code) async {
        _log('ui autoVerified sms=${code == null ? 'null' : _debugText(code)}');
        if (!mounted) return;
        setState(() {
          _sending = false;
          _codeSent = true;
          _verifying = true;
          _error = null;
        });
        if (code != null && code.trim().isNotEmpty) {
          _remember(code, reason: 'auto');
          _distribute(_storedOtp);
        }
        await _submitFirebaseToken();
      },
    );
  }

  String _digitsOf(String raw) => raw.replaceAll(RegExp(r'\D'), '');

  String _extract(List<String> parts) {
    for (final part in parts) {
      final digits = _digitsOf(part);
      if (digits.length >= 6) return digits.substring(0, 6);
    }
    final joined = parts.map(_digitsOf).join();
    if (joined.length >= 6) return joined.substring(0, 6);
    return joined;
  }

  List<String> get _boxTexts => _otpControllers.map((c) => c.text).toList();

  void _remember(String raw, {required String reason}) {
    final digits = _digitsOf(raw);
    final code = digits.length > 6 ? digits.substring(0, 6) : digits;
    _log('remember/$reason ${_debugText(raw)} -> "$code"');
    if (code.length >= _storedOtp.length) _storedOtp = code;
  }

  void _clearBoxes() {
    _applyingOtp = true;
    for (var i = 0; i < 6; i++) {
      _committed[i] = '';
      _otpControllers[i].clear();
    }
    _applyingOtp = false;
    _storedOtp = '';
  }

  void _distribute(String code) {
    _applyingOtp = true;
    for (var i = 0; i < 6; i++) {
      final char = i < code.length ? code[i] : '';
      _committed[i] = char;
      if (_digitsOf(_otpControllers[i].text) != char) {
        _otpControllers[i].value = TextEditingValue(
          text: char,
          selection: TextSelection.collapsed(offset: char.length),
        );
      }
    }
    _applyingOtp = false;
    _storedOtp = code;
  }

  void _onBoxFocus(int index) {
    if (_applyingOtp || _verifying) return;
    if (_otpFocus[index].hasFocus) {
      _prepareBox(index);
    } else {
      _stripMarker(index);
    }
  }

  void _prepareBox(int index) {
    final digit = _digitsOf(_otpControllers[index].text);
    _applyingOtp = true;
    if (digit.isEmpty) {
      _otpControllers[index].value = const TextEditingValue(
        text: _marker,
        selection: TextSelection(baseOffset: 0, extentOffset: 1),
      );
    } else {
      _otpControllers[index].value = TextEditingValue(
        text: digit,
        selection: TextSelection(baseOffset: 0, extentOffset: digit.length),
      );
    }
    _applyingOtp = false;
  }

  void _stripMarker(int index) {
    final digit = _digitsOf(_otpControllers[index].text);
    if (_otpControllers[index].text == digit) return;
    _applyingOtp = true;
    _otpControllers[index].text = digit;
    _applyingOtp = false;
  }

  void _deletePrevious(int index) {
    if (index <= 0 || _verifying) return;
    final previous = index - 1;
    _committed[previous] = '';
    _applyingOtp = true;
    _otpControllers[previous].text = '';
    _otpControllers[index].text = '';
    _applyingOtp = false;
    _storedOtp = _extract(_boxTexts);
    _log('backspace from $index -> focus $previous stored="$_storedOtp"');
    _otpFocus[previous].requestFocus();
    if (mounted) setState(() {});
  }

  void _onOtpChanged(int index, String value) {
    if (_applyingOtp) return;
    final digits = _digitsOf(value);
    final previous = _committed[index];
    _log('box $index onChanged ${_debugText(value)} digits="$digits"');

    if (digits.isEmpty) {
      _committed[index] = '';
      _applyingOtp = true;
      _otpControllers[index].text = '';
      _applyingOtp = false;
      if (previous.isEmpty) {
        _deletePrevious(index);
      } else {
        _storedOtp = _extract(_boxTexts);
        _prepareBox(index);
        _log('cleared box $index stored="$_storedOtp"');
        if (mounted) setState(() {});
      }
      return;
    }

    _applyingOtp = true;
    var cursor = index;
    for (var i = 0; i < digits.length && cursor < 6; i++, cursor++) {
      _committed[cursor] = digits[i];
      _otpControllers[cursor].value = TextEditingValue(
        text: digits[i],
        selection: const TextSelection.collapsed(offset: 1),
      );
    }
    _applyingOtp = false;
    _storedOtp = _extract(_boxTexts);
    _log('typed stored="$_storedOtp" next=$cursor');
    if (cursor < 6) {
      _otpFocus[cursor].requestFocus();
    } else {
      _prepareBox(5);
    }
    if (mounted) setState(() {});
  }

  Future<void> _verifyTypedOtp() async {
    if (_verifying || _verifyStarted) {
      _log(
        'verify skipped verifying=$_verifying started=$_verifyStarted '
        'stored="$_storedOtp"',
      );
      return;
    }
    final boxes = _boxTexts;
    final code = _extract(boxes);
    _storedOtp = code;
    _log(
      'verify stored="$_storedOtp" using="$code" '
      'boxes=${boxes.map(_debugText).join(' | ')}',
    );
    if (code.length != 6) {
      final detail =
          'len=${code.length} stored="$_storedOtp" '
          'boxes=${boxes.map((box) => _debugText(box)).join(' | ')}';
      _log('verify rejected $detail');
      setState(() => _error = 'Enter the 6-digit OTP');
      return;
    }

    _verifyStarted = true;
    _storedOtp = code;
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final token = await _firebase.confirmSmsCode(code);
      _log('firebase token len=${token.length}');
      await _finish(token);
    } catch (error) {
      _log('verify error: $error');
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _verifyStarted = false;
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
        _verifyStarted = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _finish(String idToken) async {
    final tokenPhone = PhoneVerificationService.phoneTailFromIdToken(idToken);
    _log('server confirm start tokenPhone=$tokenPhone account=$_digits');
    try {
      await _confirmOnServer(idToken);
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      final retryable = message.contains('Invalid or expired OTP') ||
          message.contains('not linked to a mobile number');
      if (!retryable) {
        await _failFinish(message);
        return;
      }
      _log('server rejected token, refreshing once: $message');
      try {
        final refreshed = await _firebase.idToken();
        await _confirmOnServer(refreshed);
      } catch (retryError) {
        await _failFinish(
          retryError.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _confirmOnServer(String idToken) async {
    await _auth.confirmPhoneVerification(idToken);
    _log('server confirm ok');
    await _firebase.signOut();
    SessionService.markPhoneVerified();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _failFinish(String message) async {
    _log('server confirm failed: $message');
    await _firebase.signOut();
    if (!mounted) return;
    setState(() {
      _sending = false;
      _verifying = false;
      _verifyStarted = false;
      _error = message;
    });
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
                  AutofillGroup(
                    child: Row(
                      children: List.generate(6, (index) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
                            child: SizedBox(
                          height: 48,
                          child: TextField(
                            controller: _otpControllers[index],
                            focusNode: _otpFocus[index],
                            enabled: !busy,
                            autofillHints: index == 0
                                ? const [AutofillHints.oneTimeCode]
                                : null,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.none,
                            textAlign: TextAlign.center,
                            enableSuggestions: false,
                            autocorrect: false,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            onTap: () {
                              _otpFocus[index].requestFocus();
                              _prepareBox(index);
                            },
                            onEditingComplete: () {},
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
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'OTP will fill automatically if the SMS arrives on this phone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: WinTheme.muted, fontSize: 12, height: 1.3),
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
