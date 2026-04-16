import 'package:flutter/widgets.dart';
import 'package:stacked/stacked.dart';

import '../../../../services/auth_service.dart';

class PhoneLoginViewModel extends BaseViewModel {
  PhoneLoginViewModel({AuthService? authService})
    : _authService = authService ?? const AuthService();

  final AuthService _authService;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController referralController = TextEditingController();

  String? errorMessage;

  Future<bool> requestOtp() async {
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
      await _authService.requestOtp(
        countryCode: countryCode,
        phoneNumber: phoneNumber,
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

  String get countryCode => '91';

  String get sanitizedPhoneNumber =>
      phoneController.text.replaceAll(RegExp(r'\D'), '');

  @override
  void dispose() {
    phoneController.dispose();
    referralController.dispose();
    super.dispose();
  }
}
