import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../otp_verification/otp_verification_view.dart';
import 'phone_login_viewmodel.dart';

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
              Text(
                'Enter your phone number',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF128C7E),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'WhatsApp will need to verify your phone number.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF667085),
                  fontSize: 14,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667085),
                    fontSize: 14,
                    height: 1.25,
                  ),
                  children: const [TextSpan(text: "What's my number?")],
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
                      keyboardType: TextInputType.phone,
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
              const SizedBox(height: 12),
              Text(
                'Carrier charges may apply',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF667085),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: viewModel.referralController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.only(bottom: 8),
                  hintText: 'REFERRAL CODE (OPTIONAL)',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    letterSpacing: 2.2,
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
              const SizedBox(height: 96),
              const SizedBox(height: 18),
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
                  width: 108,
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
                            final success = await viewModel.requestOtp();
                            if (!context.mounted || !success) {
                              return;
                            }

                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => OtpVerificationView(
                                  countryCode: viewModel.countryCode,
                                  phoneNumber: viewModel.sanitizedPhoneNumber,
                                ),
                              ),
                            );
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
                        : const Text(
                            'NEXT',
                            style: TextStyle(
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
    return Column(
      children: const [
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
