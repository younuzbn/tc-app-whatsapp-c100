import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';

import '../../admin/admin_home_view.dart';
import '../../home/home_view.dart';
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

  @override
  Widget builder(
    BuildContext context,
    OtpVerificationViewModel viewModel,
    Widget? child,
  ) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify your number'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 28),
            Text(
              'Enter the 6-digit OTP for +$countryCode $phoneNumber',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF475467),
              ),
            ),
            const SizedBox(height: 40),
            _OtpBoxes(
              controllers: viewModel.digitControllers,
              focusNodes: viewModel.digitFocus,
              enabled: !viewModel.isBusy,
              onChanged: viewModel.onDigitChanged,
            ),
            const SizedBox(height: 16),
            if (viewModel.errorMessage != null)
              Text(
                viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const Spacer(),
            SizedBox(
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                ),
                onPressed: viewModel.isBusy
                    ? null
                    : () async {
                        final authResult = await viewModel.verifyOtp();
                        if (!context.mounted || authResult == null) {
                          return;
                        }

                        await Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute<void>(
                            builder: (_) => wrapLoggedInApp(
                              authResult.isAdmin
                                  ? const AdminHomeView()
                                  : HomeView(
                                      displayPhoneNumber:
                                          authResult.displayPhoneNumber,
                                    ),
                            ),
                          ),
                          (route) => false,
                        );
                      },
                child: viewModel.isBusy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Verify OTP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
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
          width: 46,
          height: 56,
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
              fontWeight: FontWeight.w700,
              color: Color(0xFF101828),
            ),
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 2),
              ),
            ),
            onChanged: (value) => onChanged(index, value),
          ),
        );
      }),
    );
  }
}
