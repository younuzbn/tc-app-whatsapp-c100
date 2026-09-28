import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:stacked/stacked.dart';

import '../../../../services/auth_service.dart';

enum ResetPasswordStep { phone, otp, newPassword }

class ResetPasswordViewModel extends BaseViewModel {
  ResetPasswordViewModel({
    required String initialPhoneNumber,
    required this.countryCode,
    AuthService? authService,
  }) : _authService = authService ?? const AuthService() {
    phoneController.text = initialPhoneNumber;
    if (initialPhoneNumber.isNotEmpty) {
      phoneController.selection =
          TextSelection.collapsed(offset: initialPhoneNumber.length);
    }
  }

  static const otpLength = 6;
  final String countryCode;
  final AuthService _authService;

  ResetPasswordStep step = ResetPasswordStep.phone;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final List<TextEditingController> otpControllers = List.generate(
    otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> otpFocusNodes = List.generate(
    otpLength,
    (_) => FocusNode(),
  );

  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;
  String? errorMessage;

  static String normalizePhoneDigits(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 10) return digits;
    return digits.substring(digits.length - 10);
  }

  String get sanitizedPhoneNumber =>
      normalizePhoneDigits(phoneController.text);

  String get otp => otpControllers.map((c) => c.text).join();

  static final RegExp _passwordChars = RegExp(
    r"""^[A-Za-z0-9!@#\$%^&*()_+\-=\[\]{};':"\\|,.<>/?`~]+$""",
  );

  static String? validateNewPassword(String raw) {
    final password = raw.trim();
    if (password.length < 4) {
      return 'Password must be at least 4 characters';
    }
    if (!_passwordChars.hasMatch(password)) {
      return 'Use letters, numbers, or special characters only';
    }
    return null;
  }

  void toggleObscureNewPassword() {
    obscureNewPassword = !obscureNewPassword;
    notifyListeners();
  }

  void toggleObscureConfirmPassword() {
    obscureConfirmPassword = !obscureConfirmPassword;
    notifyListeners();
  }

  void onOtpDigitChanged(int index, String value) {
    if (value.length > 1) {
      otpControllers[index].text = value.characters.last;
    }
    if (value.isNotEmpty && index < otpLength - 1) {
      otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      otpFocusNodes[index - 1].requestFocus();
    }
    notifyListeners();
  }

  Future<bool> sendOtp() async {
    final phoneNumber = sanitizedPhoneNumber;
    if (phoneNumber.length != 10) {
      errorMessage = 'Enter a valid 10-digit mobile number';
      notifyListeners();
      return false;
    }

    setBusy(true);
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.requestResetPasswordOtp(
        countryCode: countryCode,
        phoneNumber: phoneNumber,
      );
      step = ResetPasswordStep.otp;
      notifyListeners();
      return true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      setBusy(false);
    }
  }

  Future<bool> verifyOtp() async {
    if (otp.length != otpLength) {
      errorMessage = 'Enter the 6-digit OTP';
      notifyListeners();
      return false;
    }

    setBusy(true);
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.verifyResetPasswordOtp(
        countryCode: countryCode,
        phoneNumber: sanitizedPhoneNumber,
        otp: otp,
      );
      step = ResetPasswordStep.newPassword;
      notifyListeners();
      return true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      setBusy(false);
    }
  }

  Future<bool> submitResetPassword() async {
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    final passErr = validateNewPassword(newPassword);
    if (passErr != null) {
      errorMessage = passErr;
      notifyListeners();
      return false;
    }

    if (newPassword.toLowerCase() != confirmPassword.toLowerCase()) {
      errorMessage = 'Passwords do not match';
      notifyListeners();
      return false;
    }

    setBusy(true);
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.confirmResetPassword(
        countryCode: countryCode,
        phoneNumber: sanitizedPhoneNumber,
        otp: otp,
        newPassword: newPassword,
      );
      return true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      setBusy(false);
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    for (final controller in otpControllers) {
      controller.dispose();
    }
    for (final node in otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}
