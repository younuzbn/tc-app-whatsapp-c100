import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';

import '../../../theme/win_theme.dart';
import 'reset_password_viewmodel.dart';

class ResetPasswordView extends StackedView<ResetPasswordViewModel> {
  const ResetPasswordView({
    super.key,
    required this.phoneNumber,
    this.countryCode = '91',
  });

  final String phoneNumber;
  final String countryCode;

  static const _bgAsset = 'assets/wallet_bg.jpeg';

  @override
  Widget builder(
    BuildContext context,
    ResetPasswordViewModel viewModel,
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Reset Password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
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
                    const SizedBox(height: 24),
                    WinGlass(
                      borderRadius: 22,
                      color: const Color(0x33101820),
                      borderColor: const Color(0x554ADE80),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _getStepSubtitle(viewModel),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFD1D5DB),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 22),
                            if (viewModel.step == ResetPasswordStep.phone) ...[
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
                                      keyboardType: TextInputType.number,
                                      enabled: !viewModel.isBusy,
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (viewModel.step ==
                                ResetPasswordStep.otp) ...[
                              _OtpBoxes(
                                controllers: viewModel.otpControllers,
                                focusNodes: viewModel.otpFocusNodes,
                                enabled: !viewModel.isBusy,
                                onChanged: viewModel.onOtpDigitChanged,
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: viewModel.isBusy
                                    ? null
                                    : () => viewModel.sendOtp(),
                                child: const Text(
                                  'Resend OTP',
                                  style: TextStyle(
                                    color: WinTheme.green,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ] else if (viewModel.step ==
                                ResetPasswordStep.newPassword) ...[
                              _GlassInput(
                                hint: 'New Password',
                                controller: viewModel.newPasswordController,
                                obscureText: viewModel.obscureNewPassword,
                                enabled: !viewModel.isBusy,
                                suffix: IconButton(
                                  onPressed:
                                      viewModel.toggleObscureNewPassword,
                                  icon: Icon(
                                    viewModel.obscureNewPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _GlassInput(
                                hint: 'Re-enter Password',
                                controller: viewModel.confirmPasswordController,
                                obscureText: viewModel.obscureConfirmPassword,
                                enabled: !viewModel.isBusy,
                                suffix: IconButton(
                                  onPressed:
                                      viewModel.toggleObscureConfirmPassword,
                                  icon: Icon(
                                    viewModel.obscureConfirmPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),
                            ],
                            if (viewModel.errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                viewModel.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            _ActionButton(
                              label: _getButtonLabel(viewModel),
                              busy: viewModel.isBusy,
                              onPressed: viewModel.isBusy
                                  ? null
                                  : () async {
                                      if (viewModel.step ==
                                          ResetPasswordStep.phone) {
                                        await viewModel.sendOtp();
                                      } else if (viewModel.step ==
                                          ResetPasswordStep.otp) {
                                        await viewModel.verifyOtp();
                                      } else if (viewModel.step ==
                                          ResetPasswordStep.newPassword) {
                                        final success =
                                            await viewModel.submitResetPassword();
                                        if (success && context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Password reset successfully! Please login with your new password.',
                                              ),
                                              backgroundColor: WinTheme.green,
                                            ),
                                          );
                                          Navigator.of(context).pop();
                                        }
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

  String _getStepSubtitle(ResetPasswordViewModel viewModel) {
    switch (viewModel.step) {
      case ResetPasswordStep.phone:
        return 'Verify your phone number to reset your password.';
      case ResetPasswordStep.otp:
        return 'Enter the 6-digit OTP sent to\n+$countryCode ${viewModel.sanitizedPhoneNumber}';
      case ResetPasswordStep.newPassword:
        return 'Enter your new password below.';
    }
  }

  String _getButtonLabel(ResetPasswordViewModel viewModel) {
    switch (viewModel.step) {
      case ResetPasswordStep.phone:
        return 'SEND OTP';
      case ResetPasswordStep.otp:
        return 'VERIFY OTP';
      case ResetPasswordStep.newPassword:
        return 'RESET PASSWORD';
    }
  }

  @override
  ResetPasswordViewModel viewModelBuilder(BuildContext context) {
    return ResetPasswordViewModel(
      initialPhoneNumber: phoneNumber,
      countryCode: countryCode,
    );
  }
}

class _GlassInput extends StatelessWidget {
  const _GlassInput({
    required this.hint,
    this.controller,
    this.enabled = true,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  final String hint;
  final TextEditingController? controller;
  final bool enabled;
  final TextInputType? keyboardType;
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

class _OtpBoxes extends StatelessWidget {
  const _OtpBoxes({
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    this.enabled = true,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(controllers.length, (index) {
        return SizedBox(
          width: 44,
          height: 54,
          child: WinGlass(
            borderRadius: 12,
            color: const Color(0x22101820),
            borderColor: const Color(0x554ADE80),
            blur: 10,
            child: TextField(
              controller: controllers[index],
              focusNode: focusNodes[index],
              enabled: enabled,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              cursorColor: WinTheme.green,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) => onChanged(index, value),
            ),
          ),
        );
      }),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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
