import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';

import '../../admin/admin_home_view.dart';
import '../../home/home_view.dart';
import '../../../theme/win_theme.dart';
import '../../update/update_gate.dart';
import 'otp_verification_viewmodel.dart';

class OtpVerificationView extends StackedView<OtpVerificationViewModel> {
  const OtpVerificationView({
    super.key,
    required this.countryCode,
    required this.phoneNumber,
  });

  final String countryCode;
  final String phoneNumber;

  static const _bgAsset = 'assets/wallet_bg.jpeg';

  @override
  Widget builder(
    BuildContext context,
    OtpVerificationViewModel viewModel,
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
              child: Padding(
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
                      'Verify OTP',
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
                    const SizedBox(height: 28),
                    WinGlass(
                      borderRadius: 22,
                      color: const Color(0x33101820),
                      borderColor: const Color(0x554ADE80),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                        child: Column(
                          children: [
                            Text(
                              'Enter the 6-digit OTP for\n+$countryCode $phoneNumber',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFD1D5DB),
                                fontSize: 14,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 28),
                            _OtpBoxes(
                              controllers: viewModel.digitControllers,
                              focusNodes: viewModel.digitFocus,
                              enabled: !viewModel.isBusy,
                              onChanged: viewModel.onDigitChanged,
                            ),
                            if (viewModel.errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                viewModel.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    DecoratedBox(
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
                          onTap: viewModel.isBusy
                              ? null
                              : () async {
                                  final authResult =
                                      await viewModel.verifyOtp();
                                  if (!context.mounted ||
                                      authResult == null) {
                                    return;
                                  }

                                  await Navigator.of(context)
                                      .pushAndRemoveUntil(
                                    MaterialPageRoute<void>(
                                      builder: (_) => wrapLoggedInApp(
                                        authResult.isAdmin
                                            ? const AdminHomeView()
                                            : HomeView(
                                                displayPhoneNumber: authResult
                                                    .displayPhoneNumber,
                                              ),
                                      ),
                                    ),
                                    (route) => false,
                                  );
                                },
                          borderRadius: BorderRadius.circular(28),
                          child: SizedBox(
                            height: 54,
                            child: Center(
                              child: viewModel.isBusy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : const Text(
                                      'Verify OTP',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
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
  OtpVerificationViewModel viewModelBuilder(BuildContext context) {
    return OtpVerificationViewModel(
      countryCode: countryCode,
      phoneNumber: phoneNumber,
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
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
              onChanged: (value) => onChanged(index, value),
            ),
          ),
        );
      }),
    );
  }
}
