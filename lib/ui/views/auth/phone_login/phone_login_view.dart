import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';

import '../../admin/admin_home_view.dart';
import '../../home/home_view.dart';
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
      // Extra keystroke while already at 10 — ignore it.
      normalized = oldDigits;
    } else {
      // Paste with country code (+91, 00…, spaces) — keep last 10 digits.
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

  @override
  Widget builder(
    BuildContext context,
    PhoneLoginViewModel viewModel,
    Widget? child,
  ) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.more_vert,
                    color: Color(0xFF475467),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Enter your phone number',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF128C7E),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                viewModel.showPasswordFields
                    ? (viewModel.step == PhoneLoginStep.passwordRegister
                          ? 'Create a password to finish signing up.'
                          : 'Enter your password to continue.')
                    : 'Win App will need your phone number to sign you in.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF667085),
                  fontSize: 14,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 18),
              const _CountrySelector(),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(flex: 2, child: _CodeField()),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: viewModel.phoneController,
                      enabled: viewModel.step == PhoneLoginStep.phone,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [_PhoneNumberInputFormatter()],
                      style: const TextStyle(
                        color: Color(0xFF1D2939),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.only(bottom: 8),
                        hintText: 'phone number',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF667085),
                        ),
                        border: UnderlineInputBorder(),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF14B8A6),
                            width: 1.6,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF14B8A6),
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (viewModel.step == PhoneLoginStep.phone) ...[
                const SizedBox(height: 20),
                TextField(
                  controller: viewModel.referralController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.only(bottom: 8),
                    hintText: 'REFERRAL CODE (REQUIRED FOR NEW USERS)',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.4,
                      color: Color(0xFF98A2B3),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFFE4E7EC),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFF14B8A6),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
              if (viewModel.showPasswordFields) ...[
                const SizedBox(height: 20),
                TextField(
                  controller: viewModel.passwordController,
                  obscureText: viewModel.obscurePassword,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.only(bottom: 8),
                    hintText: 'PASSWORD',
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.4,
                      color: Color(0xFF98A2B3),
                    ),
                    suffixIcon: IconButton(
                      onPressed: viewModel.toggleObscurePassword,
                      icon: Icon(
                        viewModel.obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF98A2B3),
                      ),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFFE4E7EC),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFF14B8A6),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
              if (viewModel.showConfirmPassword) ...[
                const SizedBox(height: 20),
                TextField(
                  controller: viewModel.confirmPasswordController,
                  obscureText: viewModel.obscurePassword,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.only(bottom: 8),
                    hintText: 'CONFIRM PASSWORD',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.4,
                      color: Color(0xFF98A2B3),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFFE4E7EC),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFF14B8A6),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
              if (viewModel.step != PhoneLoginStep.phone) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: viewModel.isBusy
                      ? null
                      : () {
                          viewModel.step = PhoneLoginStep.phone;
                          viewModel.passwordController.clear();
                          viewModel.confirmPasswordController.clear();
                          viewModel.errorMessage = null;
                          viewModel.notifyListeners();
                        },
                  child: const Text('Change number'),
                ),
              ],
              const SizedBox(height: 40),
              if (viewModel.errorMessage != null) ...[
                Text(
                  viewModel.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Center(
                child: SizedBox(
                  width: 120,
                  height: 42,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF128C7E),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: viewModel.isBusy
                        ? null
                        : () async {
                            final result = await viewModel.continueFlow();
                            if (!context.mounted) return;

                            if (result.kind == PhoneLoginResultKind.goToOtp) {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => OtpVerificationView(
                                    countryCode: viewModel.countryCode,
                                    phoneNumber:
                                        viewModel.sanitizedPhoneNumber,
                                  ),
                                ),
                              );
                              return;
                            }

                            if (result.kind == PhoneLoginResultKind.loggedIn &&
                                result.authResult != null) {
                              final auth = result.authResult!;
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute<void>(
                                  builder: (_) => auth.isAdmin
                                      ? const AdminHomeView()
                                      : HomeView(
                                          displayPhoneNumber:
                                              auth.displayPhoneNumber,
                                        ),
                                ),
                                (route) => false,
                              );
                            }
                          },
                    child: viewModel.isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            viewModel.primaryButtonLabel,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  PhoneLoginViewModel viewModelBuilder(BuildContext context) =>
      PhoneLoginViewModel();
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
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF101828),
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_drop_down, color: Color(0xFF10B981), size: 20),
          ],
        ),
        SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 68),
          child: Divider(height: 1, thickness: 1.5, color: Color(0xFF14B8A6)),
        ),
      ],
    );
  }
}

class _CodeField extends StatelessWidget {
  const _CodeField();

  @override
  Widget build(BuildContext context) {
    return const TextField(
      enabled: false,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.only(bottom: 8),
        disabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF14B8A6), width: 1.6),
        ),
        hintText: '+    91',
        hintStyle: TextStyle(
          color: Color(0xFF1D2939),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
