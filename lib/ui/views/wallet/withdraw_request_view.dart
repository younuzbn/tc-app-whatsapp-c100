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

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: WinTheme.muted),
      hintStyle: const TextStyle(color: WinTheme.muted),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: WinTheme.border),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: WinTheme.green),
      ),
    );
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
    return Scaffold(
      backgroundColor: WinTheme.bg,
      appBar: AppBar(
        backgroundColor: WinTheme.bg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Withdraw',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WinTheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WinTheme.border),
            ),
            child: Text(
              'You can withdraw winning balance (₹${WinTheme.rupee(widget.withdrawableWinnings)}) and withdrawable referral balance (₹${WinTheme.rupee(widget.withdrawableReferral)}). Deposit and non withdrawable referral cannot be withdrawn. Maximum now: ₹${WinTheme.rupee(widget.maxWithdrawable)}. One request per day, from 12 AM to 12 AM. Bank details are saved after the first request.',
              style: const TextStyle(color: WinTheme.muted, height: 1.4),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white, fontSize: 20),
            decoration: _decoration('Amount').copyWith(prefixText: '₹ '),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _account,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white),
            decoration: _decoration('Bank account number'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _accountConfirm,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white),
            decoration: _decoration('Re-enter bank account number'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ifsc,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: Colors.white),
            decoration: _decoration('IFSC code'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _upi,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: _decoration('UPI ID', hint: 'name@bank'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: WinTheme.green,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text(
                      'Send request',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
