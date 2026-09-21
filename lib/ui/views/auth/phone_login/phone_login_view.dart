import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';

import '../../admin/admin_home_view.dart';
import '../../home/home_view.dart';
import '../../../theme/win_theme.dart';
import '../../update/update_gate.dart';
import '../otp_verification/otp_verification_view.dart';
import 'phone_login_viewmodel.dart';

class _PhoneNumberInputFormatter extends TextInputFormatter {
  const _PhoneNumberInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final oldDigits = oldValue.text.replaceAll(RegExp(r'\D'), '');

    String normalized;
    if (digits.length <= 10) {
      normalized = digits;
    } else if (oldDigits.length == 10 && digits.length == oldDigits.length + 1) {
      normalized = oldDigits;
    } else {
      normalized = digits.substring(digits.length - 10);
    }

    return TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
  }
}

class PhoneLoginView extends StackedView<PhoneLoginViewModel> {
  const PhoneLoginView({super.key});

  static const _bgAsset = 'assets/wallet_bg.jpeg';

  @override
  Widget builder(
    BuildContext context,
    PhoneLoginViewModel viewModel,
    Widget? child,
  ) {
    return WinStatusBar(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: WinTheme.bg),
            const DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(_bgAsset),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    const Text(
                      'WIN APP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: WinTheme.green,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(color: Colors.black, blurRadius: 10),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: 52,
                        height: 4,
                        decoration: BoxDecoration(
                          color: WinTheme.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    WinGlass(
                      borderRadius: 22,
                      color: const Color(0x33101820),
                      borderColor: const Color(0x554ADE80),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Enter your phone number',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              viewModel.showPasswordFields
                                  ? (viewModel.step ==
                                            PhoneLoginStep.passwordRegister
                                        ? 'Create a password of at least 4 characters. Letters, numbers, or special characters are allowed.'
                                        : 'Enter your password to continue.')
                                  : 'Win App will need your phone number to sign you in.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFD1D5DB),
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 22),
                            const _CountrySelector(),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const SizedBox(
                                  width: 84,
                                  child: _GlassInput(
                                    hint: '+91',
                                    enabled: false,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _GlassInput(
                                    hint: 'Phone number',
                                    controller: viewModel.phoneController,
                                    enabled:
                                        viewModel.step == PhoneLoginStep.phone,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: const [
                                      _PhoneNumberInputFormatter(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (viewModel.step == PhoneLoginStep.phone) ...[
                              const SizedBox(height: 12),
                              _GlassInput(
                                hint: 'Referral code (new users)',
                                controller: viewModel.referralController,
                                textCapitalization:
                                    TextCapitalization.characters,
                              ),
                            ],
                            if (viewModel.showPasswordFields) ...[
                              const SizedBox(height: 12),
                              _GlassInput(
                                hint: 'Password',
                                controller: viewModel.passwordController,
                                obscureText: viewModel.obscurePassword,
                                suffix: IconButton(
                                  onPressed: viewModel.toggleObscurePassword,
                                  icon: Icon(
                                    viewModel.obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),
                            ],
                            if (viewModel.showConfirmPassword) ...[
                              const SizedBox(height: 12),
                              _GlassInput(
                                hint: 'Confirm password',
                                controller:
                                    viewModel.confirmPasswordController,
                                obscureText: viewModel.obscurePassword,
                              ),
                            ],
                            if (viewModel.step != PhoneLoginStep.phone) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: viewModel.isBusy
                                    ? null
                                    : () {
                                        viewModel.step = PhoneLoginStep.phone;
                                        viewModel.passwordController.clear();
                                        viewModel.confirmPasswordController
                                            .clear();
                                        viewModel.errorMessage = null;
                                        viewModel.notifyListeners();
                                      },
                                child: const Text(
                                  'Change number',
                                  style: TextStyle(
                                    color: WinTheme.green,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                            if (viewModel.errorMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                viewModel.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            _AuthButton(
                              label: viewModel.primaryButtonLabel,
                              busy: viewModel.isBusy,
                              onPressed: viewModel.isBusy
                                  ? null
                                  : () async {
                                      final result =
                                          await viewModel.continueFlow();
                                      if (!context.mounted) return;

                                      if (result.kind ==
                                          PhoneLoginResultKind.goToOtp) {
                                        await Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                OtpVerificationView(
                                              countryCode:
                                                  viewModel.countryCode,
                                              phoneNumber: viewModel
                                                  .sanitizedPhoneNumber,
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      if (result.kind ==
                                              PhoneLoginResultKind.loggedIn &&
                                          result.authResult != null) {
                                        final auth = result.authResult!;
                                        Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute<void>(
                                            builder: (_) => wrapLoggedInApp(
                                              auth.isAdmin
                                                  ? const AdminHomeView()
                                                  : HomeView(
                                                      displayPhoneNumber: auth
                                                          .displayPhoneNumber,
                                                    ),
                                            ),
                                          ),
                                          (route) => false,
                                        );
                                      }
                                    },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  PhoneLoginViewModel viewModelBuilder(BuildContext context) =>
      PhoneLoginViewModel();

  @override
  void onViewModelReady(PhoneLoginViewModel viewModel) {
    unawaited(viewModel.prefetchReferralCode());
  }
}

class _CountrySelector extends StatelessWidget {
  const _CountrySelector();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'India',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_drop_down, color: WinTheme.green, size: 22),
          ],
        ),
        SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 48),
          child: Divider(height: 1, thickness: 1.5, color: WinTheme.green),
        ),
      ],
    );
  }
}

class _GlassInput extends StatelessWidget {
  const _GlassInput({
    required this.hint,
    this.controller,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.suffix,
  });

  final String hint;
  final TextEditingController? controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return WinGlass(
      borderRadius: 16,
      color: const Color(0x22101820),
      borderColor: const Color(0x33FFFFFF),
      blur: 12,
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        obscureText: obscureText,
        style: TextStyle(
          color: enabled ? Colors.white : const Color(0xFFD1D5DB),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        cursorColor: WinTheme.green,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFF8B9A9F),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x6616A34A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: 50,
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
