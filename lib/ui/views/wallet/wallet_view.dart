import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/android_image_picker.dart';
import '../../../services/sales_service.dart';
import '../../../services/wallet_service.dart';
import '../../theme/win_theme.dart';
import 'withdraw_request_view.dart';

class WalletView extends StatefulWidget {
  const WalletView({super.key});

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  final _service = const WalletService();
  final _salesService = const SalesService();
  bool _loading = true;
  String? _error;
  WalletSummary? _summary;
  List<WalletTransactionItem> _transactions = [];
  List<WithdrawRequestItem> _withdrawals = [];
  List<WalletTopupMessage> _topups = [];
  PayoutDetails _payoutDetails = const PayoutDetails();

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
      final summary = await _service.fetchSummary();
      final txs = summary.isAdminWallet
          ? <WalletTransactionItem>[]
          : await _service.fetchTransactions();
      var withdrawals = <WithdrawRequestItem>[];
      var payout = summary.payoutDetails;
      var topups = <WalletTopupMessage>[];
      if (!summary.isAdminWallet) {
        final withdrawData = await _service.fetchWithdrawRequests();
        withdrawals = withdrawData.requests;
        if (withdrawData.payoutDetails.hasSavedDetails) {
          payout = withdrawData.payoutDetails;
        }
        try {
          topups = await _salesService.getMyWalletTopups();
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _transactions = txs;
        _withdrawals = withdrawals;
        _topups = topups;
        _payoutDetails = payout;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _addMoney() async {
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => const _AmountDialog(
        title: 'Add Money',
        confirmLabel: 'Continue',
      ),
    );
    if (amount == null || !mounted) return;

    final proof = await showDialog<_PaymentProof?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PaymentProofDialog(amount: amount),
    );
    if (proof == null || !mounted) return;

    try {
      final summary = await _service.addFunds(
        amount: amount,
        screenshotBase64: proof.screenshotBase64,
        screenshotMime: proof.screenshotMime,
      );
      if (!mounted) return;
      setState(() => _summary = summary);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Add money request sent for ₹${WinTheme.rupee(amount)}. Deposit will be credited after admin verifies the payment.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _withdraw() async {
    final winnings = _summary?.withdrawable ?? 0;
    if (winnings <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Only prize winnings can be withdrawn. Deposit and referral money can only be used to play.',
          ),
        ),
      );
      return;
    }
    final sent = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => WithdrawRequestView(
          maxWithdrawable: winnings,
          savedDetails: _payoutDetails,
        ),
      ),
    );
    if (sent == true && mounted) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Withdraw request sent.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final admin = summary?.isAdminWallet == true;

    return Scaffold(
      backgroundColor: WinTheme.bg,
      appBar: AppBar(
        backgroundColor: WinTheme.bg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Wallet',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: WinTheme.green))
          : RefreshIndicator(
              color: WinTheme.green,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                    decoration: BoxDecoration(
                      color: WinTheme.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: WinTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL AMOUNT',
                          style: TextStyle(
                            color: WinTheme.muted,
                            fontSize: 12,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          admin ? '—' : '₹${WinTheme.rupee(summary?.total ?? 0)}',
                          style: const TextStyle(
                            color: WinTheme.green,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _BalanceRow(
                          color: WinTheme.yellow,
                          label: 'Deposit',
                          value: admin ? '—' : '₹${WinTheme.rupee(summary?.deposit ?? 0)}',
                        ),
                        const SizedBox(height: 10),
                        _BalanceRow(
                          color: WinTheme.green,
                          label: 'Winning',
                          value: admin ? '—' : '₹${WinTheme.rupee(summary?.winningsBalance ?? 0)}',
                          valueColor: WinTheme.green,
                        ),
                        const SizedBox(height: 10),
                        _BalanceRow(
                          color: WinTheme.blue,
                          label: 'Refer earn',
                          value: admin ? '—' : '₹${WinTheme.rupee(summary?.referralBalance ?? 0)}',
                        ),
                        if (!admin && (summary?.lockedBalance ?? 0) > 0) ...[
                          const SizedBox(height: 10),
                          _BalanceRow(
                            color: Colors.orangeAccent,
                            label: 'Processing withdraw',
                            value: '₹${WinTheme.rupee(summary!.lockedBalance)}',
                            valueColor: Colors.orangeAccent,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: WinTheme.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: WinTheme.border),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: WinTheme.muted, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Deposit is money you added. Refer earn is money from referrals. Playing uses deposit first, then referral. Only Winning can be withdrawn. Add money and withdraw requests show as Processing, then Processed or Failed.',
                            style: TextStyle(
                              color: WinTheme.muted,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!admin) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: _addMoney,
                              icon: const Icon(Icons.add, color: Colors.black),
                              label: const Text(
                                'Add Money',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: WinTheme.green,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _withdraw,
                              icon: const Icon(Icons.arrow_upward_rounded),
                              label: const Text(
                                'Withdraw',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: WinTheme.green,
                                side: const BorderSide(color: WinTheme.green),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_topups.isNotEmpty) ...[
                      const Text(
                        'Deposit requests',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._topups.map((item) => _DepositTile(item: item)),
                      const SizedBox(height: 24),
                    ],
                    if (_withdrawals.isNotEmpty) ...[
                      const Text(
                        'Withdraw requests',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._withdrawals.map((item) => _WithdrawTile(item: item)),
                      const SizedBox(height: 24),
                    ],
                    Row(
                      children: [
                        const Text(
                          'Transaction History',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_transactions.length} transactions',
                          style: const TextStyle(color: WinTheme.muted, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_transactions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'No transactions yet.',
                          style: TextStyle(color: WinTheme.muted),
                        ),
                      )
                    else
                      ..._transactions.map((tx) => _TransactionTile(item: tx)),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
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

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.color,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final Color color;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(color: WinTheme.muted, fontSize: 14)),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.item});

  final WalletTransactionItem item;

  @override
  Widget build(BuildContext context) {
    final credit = item.direction == 'credit';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WinTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WinTheme.border),
      ),
      child: Row(
        children: [
          Icon(
            credit ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: credit ? WinTheme.green : Colors.orangeAccent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.description.isNotEmpty)
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: WinTheme.muted, fontSize: 12),
                  ),
              ],
            ),
          ),
          Text(
            '${credit ? '+' : '-'}₹${WinTheme.rupee(item.amount)}',
            style: TextStyle(
              color: credit ? WinTheme.green : Colors.orangeAccent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountDialog extends StatefulWidget {
  const _AmountDialog({required this.title, required this.confirmLabel});

  final String title;
  final String confirmLabel;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: WinTheme.surface,
      title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(color: Colors.white, fontSize: 20),
        decoration: const InputDecoration(
          prefixText: '₹ ',
          prefixStyle: TextStyle(color: WinTheme.green, fontSize: 20),
          hintText: 'Amount',
          hintStyle: TextStyle(color: WinTheme.muted),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final amount = double.tryParse(_controller.text.trim());
            if (amount == null || amount <= 0) return;
            Navigator.pop(context, amount);
          },
          style: FilledButton.styleFrom(backgroundColor: WinTheme.green),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

class _DepositTile extends StatelessWidget {
  const _DepositTile({required this.item});

  final WalletTopupMessage item;

  Color _statusColor() {
    if (item.isCredited) return WinTheme.green;
    if (item.isRejected) return Colors.redAccent;
    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WinTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WinTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_card_outlined, color: WinTheme.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${WinTheme.rupee(item.amount)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'Add money request',
                  style: TextStyle(color: WinTheme.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            item.userStatus,
            style: TextStyle(
              color: _statusColor(),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawTile extends StatelessWidget {
  const _WithdrawTile({required this.item});

  final WithdrawRequestItem item;

  void _openImage(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                url,
                errorBuilder: (_, _, _) => const Text(
                  'Unable to load image',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final proofUrl = item.status == 'rejected' ? item.rejectImageUrl : item.receiptUrl;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WinTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WinTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.south_west_rounded, color: WinTheme.green, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${WinTheme.rupee(item.amount)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      item.upiId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: WinTheme.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                item.displayStatus,
                style: TextStyle(
                  color: item.statusColor(),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (item.status == 'rejected' && item.rejectReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.rejectReason,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
          if (proofUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _openImage(context, proofUrl),
              borderRadius: BorderRadius.circular(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  proofUrl,
                  height: 88,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentProof {
  const _PaymentProof({
    required this.screenshotBase64,
    required this.screenshotMime,
  });

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
  File? _imageFile;
  String? _error;
  bool _picking = false;

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
              'Upload the payment screenshot. Admin will verify it, then the amount is credited to deposit.',
              style: TextStyle(color: Color(0xFF8696A0), fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
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
                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                        : const Icon(Icons.image_outlined, color: Color(0xFF8696A0)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _picking ? null : _pickImage,
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: Text(
                      _imageFile == null ? 'Upload screenshot' : 'Change screenshot',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(color: Color(0xFF2A3942)),
                    ),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
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
