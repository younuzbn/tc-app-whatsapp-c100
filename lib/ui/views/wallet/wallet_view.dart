import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/android_image_picker.dart';
import '../../../services/auth_service.dart';
import '../../../services/session_service.dart';
import '../../../services/wallet_service.dart';

class WalletView extends StatefulWidget {
  const WalletView({super.key});

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  static const Color _bg = Color(0xFF0B141A);
  static const Color _surface = Color(0xFF111B21);
  static const Color _green = Color(0xFF25D366);
  static const Color _muted = Color(0xFF8696A0);

  final _service = const WalletService();
  final _authService = const AuthService();
  final _amountController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  double? _balance;
  bool _isAdminWallet = false;
  String _referralCode = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final b = await _service.fetchBalance();
      final code = await _authService.fetchMyReferralCode();
      if (!mounted) return;
      setState(() {
        _balance = b;
        _isAdminWallet = b == null;
        _referralCode = code?.trim() ?? SessionService.referralCode?.trim() ?? '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _referralCode = SessionService.referralCode?.trim() ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _add() async {
    final raw = _amountController.text.trim();
    final amount = double.tryParse(raw);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount greater than zero.');
      return;
    }

    final proof = await showDialog<_PaymentProof?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PaymentProofDialog(amount: amount),
    );
    if (proof == null || !mounted) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final newBal = await _service.addFunds(
        amount: amount,
        uti: proof.uti,
        screenshotBase64: proof.screenshotBase64,
        screenshotMime: proof.screenshotMime,
      );
      if (!mounted) return;
      _amountController.clear();
      setState(() {
        _balance = newBal;
        _saving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added ₹${_fmt(amount)}. New balance ₹${_fmt(newBal)}.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  String _fmt(double v) {
    if (v.truncateToDouble() == v) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phone = SessionService.displayPhoneNumber ?? SessionService.username ?? '';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Wallet'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : RefreshIndicator(
              color: _green,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    phone,
                    style: const TextStyle(color: _muted, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2A3942)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Available balance',
                          style: TextStyle(color: _muted, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isAdminWallet
                              ? '—'
                              : '₹${_fmt(_balance ?? 0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (_isAdminWallet) ...[
                          const SizedBox(height: 12),
                          Text(
                            SessionService.isAdmin
                                ? 'Admin account does not use wallet balance.'
                                : 'Wallet is not available for this login.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: _muted, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!_isAdminWallet) ...[
                    const SizedBox(height: 28),
                    const Text(
                      'Add money',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter amount, then upload payment screenshot and UPI Transaction ID to credit your wallet.',
                      style: TextStyle(color: _muted, fontSize: 13, height: 1.35),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                      decoration: InputDecoration(
                        labelText: 'Amount (₹)',
                        labelStyle: const TextStyle(color: _muted),
                        prefixText: '₹ ',
                        prefixStyle: const TextStyle(color: _green, fontSize: 20),
                        filled: true,
                        fillColor: _surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2A3942)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2A3942)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _green),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _saving ? null : _add,
                        style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_saving ? 'Adding…' : 'Add to wallet'),
                      ),
                    ),
                  ],
                  if (!_isAdminWallet) ...[
                    const SizedBox(height: 28),
                    _ReferAndEarnCard(
                      referralCode: _referralCode,
                      onCopied: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Referral code copied')),
                        );
                      },
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _ReferAndEarnCard extends StatelessWidget {
  const _ReferAndEarnCard({
    required this.referralCode,
    required this.onCopied,
  });

  final String referralCode;
  final VoidCallback onCopied;

  static const Color _surface = Color(0xFF111B21);
  static const Color _muted = Color(0xFF8696A0);
  static const Color _accent = Color(0xFF4B9B8B);

  @override
  Widget build(BuildContext context) {
    final code = referralCode.trim().isEmpty ? '—' : referralCode.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3942)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.card_giftcard, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Refer & Earn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Share your referral code with friends. They can enter it when signing up.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your referral code',
            style: TextStyle(color: _muted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0B141A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A3942)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: code == '—'
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: code));
                          onCopied();
                        },
                  icon: const Icon(Icons.copy_rounded, color: _accent),
                  tooltip: 'Copy code',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentProof {
  const _PaymentProof({
    required this.uti,
    required this.screenshotBase64,
    required this.screenshotMime,
  });

  final String uti;
  final String screenshotBase64;
  final String screenshotMime;
}

class _PaymentProofDialog extends StatefulWidget {
  const _PaymentProofDialog({required this.amount});

  final double amount;

  @override
  State<_PaymentProofDialog> createState() => _PaymentProofDialogState();
}

class _PaymentProofDialogState extends State<_PaymentProofDialog> {
  final _utiController = TextEditingController();
  File? _imageFile;
  String? _error;
  bool _picking = false;

  @override
  void dispose() {
    _utiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final path = await AndroidImagePicker.pickImage();
      if (!mounted) return;
      if (path == null) {
        setState(() => _picking = false);
        return;
      }
      setState(() {
        _imageFile = File(path);
        _picking = false;
        _error = null;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _picking = false;
        _error = e.message?.isNotEmpty == true
            ? e.message
            : 'Could not open gallery. Please reinstall the latest APK.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _picking = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _submit() async {
    final uti = _utiController.text.trim();
    if (uti.length < 4) {
      setState(() => _error = 'Enter a valid UPI Transaction ID');
      return;
    }
    if (_imageFile == null) {
      setState(() => _error = 'Upload payment screenshot');
      return;
    }
    final bytes = await _imageFile!.readAsBytes();
    final path = _imageFile!.path.toLowerCase();
    final mime = path.endsWith('.png')
        ? 'image/png'
        : path.endsWith('.webp')
        ? 'image/webp'
        : 'image/jpeg';
    if (!mounted) return;
    Navigator.of(context).pop(
      _PaymentProof(
        uti: uti,
        screenshotBase64: base64Encode(bytes),
        screenshotMime: mime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF111B21),
      title: Text(
        'Payment proof · ₹${widget.amount.toStringAsFixed(0)}',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upload payment screenshot and enter UPI Transaction ID to credit wallet.',
              style: TextStyle(color: Color(0xFF8696A0), fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _utiController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'UPI Transaction ID',
                labelStyle: TextStyle(color: Color(0xFF8696A0)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2A3942)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF25D366)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap: _picking ? null : _pickImage,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B141A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2A3942)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _picking
                        ? const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF25D366),
                              ),
                            ),
                          )
                        : _imageFile != null
                        ? Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                            width: 72,
                            height: 72,
                          )
                        : const Icon(
                            Icons.image_outlined,
                            color: Color(0xFF8696A0),
                            size: 28,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _picking ? null : _pickImage,
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: Text(
                      _imageFile == null
                          ? 'Upload screenshot'
                          : 'Change screenshot',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(color: Color(0xFF2A3942)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            if (_imageFile != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Screenshot selected',
                style: TextStyle(color: Color(0xFF25D366), fontSize: 12),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _picking ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
