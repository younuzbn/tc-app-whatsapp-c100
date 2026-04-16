import 'package:flutter/widgets.dart';
import 'package:stacked/stacked.dart';

import '../../../../services/auth_service.dart';

class OtpVerificationViewModel extends BaseViewModel {
  OtpVerificationViewModel({
    required this.countryCode,
    required this.phoneNumber,
    AuthService? authService,
  }) : _authService = authService ?? const AuthService();

  final String countryCode;
  final String phoneNumber;
  final AuthService _authService;

  final TextEditingController otpController = TextEditingController();

  String? errorMessage;

  Future<MobileAuthResult?> verifyOtp() async {
    final otp = otpController.text.trim();
    if (otp.length != 4) {
      errorMessage = 'Enter the 4-digit OTP';
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
    otpController.dispose();
    super.dispose();
  }
}
