import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/wallet_service.dart';
import '../../theme/win_theme.dart';

class WithdrawRequestView extends StatefulWidget {
  const WithdrawRequestView({
    super.key,
    required this.maxWithdrawable,
    required this.savedDetails,
    this.withdrawableWinnings = 0,
    this.withdrawableReferral = 0,
  });

  final double maxWithdrawable;
  final double withdrawableWinnings;
  final double withdrawableReferral;
  final PayoutDetails savedDetails;

  @override
  State<WithdrawRequestView> createState() => _WithdrawRequestViewState();
}

class _WithdrawRequestViewState extends State<WithdrawRequestView> {
  static const _bgAsset = 'assets/wallet_bg.jpeg';

  final _service = const WalletService();
  final _amount = TextEditingController();
  final _account = TextEditingController();
  final _accountConfirm = TextEditingController();
  final _ifsc = TextEditingController();
  final _upi = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final saved = widget.savedDetails;
    if (saved.hasSavedDetails) {
      _account.text = saved.accountNumber;
      _accountConfirm.text = saved.accountNumber;
      _ifsc.text = saved.ifsc;
      _upi.text = saved.upiId;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _account.dispose();
    _accountConfirm.dispose();
    _ifsc.dispose();
    _upi.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amount.text.trim());
    final account = _account.text.replaceAll(RegExp(r'\s+'), '');
    final account2 = _accountConfirm.text.replaceAll(RegExp(r'\s+'), '');
    final ifsc = _ifsc.text.trim().toUpperCase();
    final upi = _upi.text.trim().toLowerCase();

    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    if (amount > widget.maxWithdrawable) {
      setState(
        () => _error =
            'Maximum you can withdraw is ₹${WinTheme.rupee(widget.maxWithdrawable)}.',
      );
      return;
    }
    if (!RegExp(r'^\d{9,18}$').hasMatch(account)) {
      setState(() => _error = 'Enter a valid bank account number (9 to 18 digits).');
      return;
    }
    if (account != account2) {
      setState(() => _error = 'Bank account numbers do not match.');
      return;
    }
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc)) {
      setState(() => _error = 'Enter a valid IFSC code.');
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9._-]{2,}@[a-zA-Z][a-zA-Z0-9.-]{1,}$').hasMatch(upi)) {
      setState(() => _error = 'Enter a valid UPI ID, like name@bank.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _service.withdraw(
        amount: amount,
        accountNumber: account,
        accountNumberConfirm: account2,
        ifsc: ifsc,
        upiId: upi,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: Column(
                children: [
                  _Header(onBack: () => Navigator.of(context).maybePop()),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      children: [
                        _InfoBanner(
                          text:
                              'You can withdraw winning balance (₹${WinTheme.rupee(widget.withdrawableWinnings)}) and withdrawable referral balance (₹${WinTheme.rupee(widget.withdrawableReferral)}). Deposit and non withdrawable referral cannot be withdrawn. Maximum now: ₹${WinTheme.rupee(widget.maxWithdrawable)}. One request per day, from 12 AM to 12 AM. Bank details are saved after the first request.',
                        ),
                        const SizedBox(height: 16),
                        _GlassField(
                          icon: Icons.currency_rupee_rounded,
                          hint: 'Amount',
                          controller: _amount,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        const SizedBox(height: 10),
                        _GlassField(
                          icon: Icons.account_balance_outlined,
                          hint: 'Bank account number',
                          controller: _account,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        const SizedBox(height: 10),
                        _GlassField(
                          icon: Icons.account_balance_rounded,
                          hint: 'Re-enter bank account number',
                          controller: _accountConfirm,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        const SizedBox(height: 10),
                        _GlassField(
                          icon: Icons.description_outlined,
                          hint: 'IFSC code',
                          controller: _ifsc,
                          textCapitalization: TextCapitalization.characters,
                        ),
                        const SizedBox(height: 10),
                        _GlassField(
                          icon: Icons.bolt_rounded,
                          hint: 'UPI ID',
                          controller: _upi,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ],
                        const SizedBox(height: 22),
                        _SendButton(
                          submitting: _submitting,
                          onPressed: _submitting ? null : _submit,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: Colors.white,
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Withdraw',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              SizedBox(
                width: 46,
                height: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: WinTheme.green,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF22C55E).withValues(alpha: 0.28),
                const Color(0xFF14532D).withValues(alpha: 0.42),
              ],
            ),
            border: Border.all(color: const Color(0x664ADE80)),
            boxShadow: const [
              BoxShadow(color: Color(0x3316A34A), blurRadius: 18),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: WinTheme.yellow,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'i',
                  style: TextStyle(
                    color: Color(0xFF3F2A00),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.4,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassField extends StatelessWidget {
  const _GlassField({
    required this.icon,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          decoration: BoxDecoration(
            color: const Color(0x66101820),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0x2216A34A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: WinTheme.green, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  textCapitalization: textCapitalization,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: WinTheme.green,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: Color(0xFF8B9A9F),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.submitting, required this.onPressed});

  final bool submitting;
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
            blurRadius: 18,
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
            height: 54,
            child: submitting
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    ),
                  )
                : const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Send request',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Color(0x33000000),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.black,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
