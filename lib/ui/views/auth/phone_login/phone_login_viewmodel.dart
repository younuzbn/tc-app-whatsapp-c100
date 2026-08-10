import 'package:flutter/widgets.dart';
import 'package:stacked/stacked.dart';

import '../../../../services/auth_service.dart';

enum PhoneLoginStep { phone, passwordLogin, passwordRegister }

class PhoneLoginActionResult {
  const PhoneLoginActionResult({
    required this.kind,
    this.authResult,
  });

  final PhoneLoginResultKind kind;
  final MobileAuthResult? authResult;
}

enum PhoneLoginResultKind { stay, goToOtp, loggedIn }

class PhoneLoginViewModel extends BaseViewModel {
  PhoneLoginViewModel({AuthService? authService})
    : _authService = authService ?? const AuthService();

  final AuthService _authService;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController referralController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String? errorMessage;
  PhoneLoginStep step = PhoneLoginStep.phone;
  bool obscurePassword = true;

  String get countryCode => '91';

  String get sanitizedPhoneNumber =>
      phoneController.text.replaceAll(RegExp(r'\D'), '');

  String get sanitizedReferralCode =>
      referralController.text.trim().toUpperCase().replaceAll(
        RegExp(r'[^A-Z0-9]'),
        '',
      );

  String get primaryButtonLabel {
    switch (step) {
      case PhoneLoginStep.phone:
        return 'NEXT';
      case PhoneLoginStep.passwordLogin:
        return 'LOGIN';
      case PhoneLoginStep.passwordRegister:
        return 'CREATE';
    }
  }

  bool get showPasswordFields =>
      step == PhoneLoginStep.passwordLogin ||
      step == PhoneLoginStep.passwordRegister;

  bool get showConfirmPassword => step == PhoneLoginStep.passwordRegister;

  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  Future<PhoneLoginActionResult> continueFlow() async {
    final phoneNumber = sanitizedPhoneNumber;
    if (phoneNumber.length != 10) {
      errorMessage = 'Enter a valid 10-digit mobile number';
      notifyListeners();
      return const PhoneLoginActionResult(kind: PhoneLoginResultKind.stay);
    }

    if (step == PhoneLoginStep.phone) {
      return _checkPhone(phoneNumber);
    }
    if (step == PhoneLoginStep.passwordLogin) {
      return _login(phoneNumber);
    }
    return _register(phoneNumber);
  }

  Future<PhoneLoginActionResult> _checkPhone(String phoneNumber) async {
    setBusy(true);
    errorMessage = null;
    notifyListeners();

    try {
      final referral = sanitizedReferralCode;
      final result = await _authService.checkPhone(
        countryCode: countryCode,
        phoneNumber: phoneNumber,
        referralCode: referral.isEmpty ? null : referral,
      );

      if (result.isAdminNumber) {
        await _authService.requestOtp(
          countryCode: countryCode,
          phoneNumber: phoneNumber,
        );
        return const PhoneLoginActionResult(kind: PhoneLoginResultKind.goToOtp);
      }

      if (result.exists) {
        step = PhoneLoginStep.passwordLogin;
        notifyListeners();
        return const PhoneLoginActionResult(kind: PhoneLoginResultKind.stay);
      }

      if (referral.isEmpty) {
        errorMessage = 'Please enter referral code';
        notifyListeners();
        return const PhoneLoginActionResult(kind: PhoneLoginResultKind.stay);
      }

      if (result.referralValid != true) {
        errorMessage = 'Invalid referral code';
        notifyListeners();
        return const PhoneLoginActionResult(kind: PhoneLoginResultKind.stay);
      }

      step = PhoneLoginStep.passwordRegister;
      notifyListeners();
      return const PhoneLoginActionResult(kind: PhoneLoginResultKind.stay);
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return const PhoneLoginActionResult(kind: PhoneLoginResultKind.stay);
    } finally {
      setBusy(false);
    }
  }

  Future<PhoneLoginActionResult> _login(String phoneNumber) async {
    final password = passwordController.text;
    if (password.isEmpty) {
      errorMessage = 'Enter your password';
      notifyListeners();
      return const PhoneLoginActionResult(kind: PhoneLoginResultKind.stay);
    }

    setBusy(true);
    errorMessage = null;
    notifyListeners();

    try {
      final authResult = await _authService.loginWithPassword(
        countryCode: countryCode,
        phoneNumber: phoneNumber,
        password: password,
      );
      return PhoneLoginActionResult(
        kind: PhoneLoginResultKind.loggedIn,
        authResult: authResult,
      );
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return const PhoneLoginActionResult(kind: PhoneLoginResultKind.stay);
    } finally {
      setBusy(false);
    }
  }

  Future<PhoneLoginActionResult> _register(String phoneNumber) async {
    final password = passwordController.text;
    final confirm = confirmPasswordController.text;
    final referral = sanitizedReferralCode;

    if (referral.isEmpty) {
      errorMessage = 'Please enter referral code';
      notifyListeners();
      return const PhoneLoginActionResult(kind: PhoneLoginResultKind.stay);
    }
    if (password.length < 3) {
      errorMessage = 'Password must be at least 3 characters';
      notifyListeners();
      return const PhoneLoginActionResult(kind: PhoneLoginResultKind.stay);
    }
    // Passwords are case-insensitive (WTh / wth / WTH all match).
    if (password.toLowerCase() != confirm.toLowerCase()) {
      errorMessage = 'Passwords do not match';
      notifyListeners();
      return const PhoneLoginActionResult(kind: PhoneLoginResultKind.stay);
    }

    setBusy(true);
    errorMessage = null;
    notifyListeners();

    try {
      final authResult = await _authService.register(
        countryCode: countryCode,
        phoneNumber: phoneNumber,
        password: password,
        referralCode: referral,
      );
      return PhoneLoginActionResult(
        kind: PhoneLoginResultKind.loggedIn,
        authResult: authResult,
      );
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return const PhoneLoginActionResult(kind: PhoneLoginResultKind.stay);
    } finally {
      setBusy(false);
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    referralController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
