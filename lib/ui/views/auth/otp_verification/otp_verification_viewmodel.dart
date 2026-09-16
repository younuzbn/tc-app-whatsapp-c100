import 'package:flutter/widgets.dart';
import 'package:stacked/stacked.dart';

import '../../../../services/auth_service.dart';

class OtpVerificationViewModel extends BaseViewModel {
  OtpVerificationViewModel({
    required this.countryCode,
    required this.phoneNumber,
    AuthService? authService,
  }) : _authService = authService ?? const AuthService();

  static const otpLength = 6;

  final String countryCode;
  final String phoneNumber;
  final AuthService _authService;

  final List<TextEditingController> digitControllers = List.generate(
    otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> digitFocus = List.generate(otpLength, (_) => FocusNode());

  String? errorMessage;

  String get otp => digitControllers.map((c) => c.text).join();

  void onDigitChanged(int index, String value) {
    if (value.length > 1) {
      digitControllers[index].text = value.characters.last;
    }
    if (value.isNotEmpty && index < otpLength - 1) {
      digitFocus[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      digitFocus[index - 1].requestFocus();
    }
    notifyListeners();
  }

  Future<MobileAuthResult?> verifyOtp() async {
    if (otp.length != otpLength) {
      errorMessage = 'Enter the 6-digit OTP';
      notifyListeners();
      return null;
    }

    setBusy(true);
    errorMessage = null;
    notifyListeners();

    try {
      return await _authService.verifyOtp(
        countryCode: countryCode,
        phoneNumber: phoneNumber,
        otp: otp,
      );
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      setBusy(false);
    }
  }

  @override
  void dispose() {
    for (final controller in digitControllers) {
      controller.dispose();
    }
    for (final node in digitFocus) {
      node.dispose();
    }
    super.dispose();
  }
}
