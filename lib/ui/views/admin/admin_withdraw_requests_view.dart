import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/android_image_picker.dart';
import '../../../services/wallet_service.dart';
import '../wallet/withdraw_payment_processed_view.dart';

class AdminWithdrawRequestsView extends StatefulWidget {
  const AdminWithdrawRequestsView({super.key});

  @override
  State<AdminWithdrawRequestsView> createState() =>
      _AdminWithdrawRequestsViewState();
}

class _AdminWithdrawRequestsViewState extends State<AdminWithdrawRequestsView> {
  static const Color _bg = Color(0xFF07090C);
  static const Color _surface = Color(0xFF12161C);
  static const Color _card = Color(0xFF171C23);
  static const Color _line = Color(0xFF2A323C);
  static const Color _muted = Color(0xFF8B95A1);
  static const Color _green = Color(0xFF2FCB71);
  static const Color _cream = Color(0xFFF4F1EA);

  final _service = const WalletService();
  bool _loading = true;
  String? _error;
  String _filter = 'processing';
  String? _busyId;
  List<WithdrawRequestItem> _items = [];

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
      final items = await _service.fetchAdminWithdrawRequests(status: _filter);
      if (!mounted) return;
      setState(() {
        _items = items;
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

  String _rupee(double amount) {
    if (amount.truncateToDouble() == amount) return amount.toStringAsFixed(0);
    return amount.toStringAsFixed(2);
  }

  Future<void> _copy(String label, String value) async {
    if (value.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value.trim()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _card,
        content: Text(
          '$label copied',
          style: const TextStyle(color: _cream),
        ),
      ),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            color: _cream,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          body,
          style: const TextStyle(color: _muted, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<({String base64, String mime, Uint8List bytes})?> _pickProof() async {
    try {
      final path = await AndroidImagePicker.pickImage();
      if (!mounted || path == null || path.isEmpty) return null;
      final bytes = await File(path).readAsBytes();
      if (bytes.length > 6 * 1024 * 1024) {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: _card,
            content: Text(
              'Image must be smaller than 6MB',
              style: TextStyle(color: Color(0xFFFF8A80)),
            ),
          ),
        );
        return null;
      }
      final lower = path.toLowerCase();
      final mime = lower.endsWith('.png')
          ? 'image/png'
          : lower.endsWith('.webp')
          ? 'image/webp'
          : 'image/jpeg';
      return (base64: base64Encode(bytes), mime: mime, bytes: bytes);
    } on PlatformException catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _card,
          content: Text(
            e.message?.isNotEmpty == true
                ? e.message!
                : 'Could not open gallery. Reinstall the latest APK.',
            style: const TextStyle(color: Color(0xFFFF8A80)),
          ),
        ),
      );
      return null;
    }
  }

  Future<bool> _confirmWithdraw({
    required String amount,
    required String phone,
    required Uint8List preview,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Mark as withdraw?',
          style: TextStyle(
            color: _cream,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Confirm you have sent $amount to $phone. This screenshot will be shown to the user.',
              style: const TextStyle(color: _muted, height: 1.4),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                preview,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Mark as withdraw'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _act(WithdrawRequestItem item, String action) async {
    if (_busyId != null) return;
    final amount = '₹${_rupee(item.amount)}';
    final phone = item.phoneNumber.isNotEmpty ? item.phoneNumber : item.username;
    final isReject = action == 'reject';
    String? imageBase64;
    String imageMime = 'image/jpeg';

    if (isReject) {
      final confirmed = await _confirm(
        title: 'Reject request?',
        body: 'Return $amount to $phone. This request will be marked rejected.',
        confirmLabel: 'Reject',
        confirmColor: const Color(0xFFDC4A4A),
      );
      if (!confirmed || !mounted) return;
    } else {
      final picked = await _pickProof();
      if (picked == null || !mounted) return;
      imageBase64 = picked.base64;
      imageMime = picked.mime;
      final confirmed = await _confirmWithdraw(
        amount: amount,
        phone: phone,
        preview: picked.bytes,
      );
      if (!confirmed || !mounted) return;
    }

    setState(() => _busyId = item.id);
    try {
      await _service.updateAdminWithdrawRequest(
        id: item.id,
        action: action,
        rejectReason: isReject ? 'Rejected' : '',
        imageBase64: imageBase64,
        imageMime: imageMime,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _card,
          content: Text(
            isReject ? 'Request rejected' : 'Marked as withdrawn',
            style: const TextStyle(color: _cream),
          ),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _card,
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: const TextStyle(color: Color(0xFFFF8A80)),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _replaceReceipt(WithdrawRequestItem item) async {
    if (_busyId != null) return;
    final picked = await _pickProof();
    if (picked == null || !mounted) return;
    final confirmed = await _confirm(
      title: 'Replace screenshot?',
      body: 'This payment screenshot will be shown to the user.',
      confirmLabel: 'Save screenshot',
      confirmColor: _green,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busyId = item.id);
    try {
      await _service.updateAdminWithdrawRequest(
        id: item.id,
        action: 'receipt',
        imageBase64: picked.base64,
        imageMime: picked.mime,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: _card,
          content: Text(
            'Screenshot updated',
            style: TextStyle(color: _cream),
          ),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _card,
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: const TextStyle(color: Color(0xFFFF8A80)),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _cream,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Withdrawals',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _line),
              ),
              child: Row(
                children: [
                  for (final tab in const [
                    ('processing', 'Pending'),
                    ('processed', 'Withdrawn'),
                    ('failed', 'Rejected'),
                  ])
                    Expanded(
                      child: _FilterTab(
                        label: tab.$2,
                        selected: _filter == tab.$1,
                        onTap: () {
                          if (_filter == tab.$1) return;
                          setState(() => _filter = tab.$1);
                          _load();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _green))
                : RefreshIndicator(
                    color: _green,
                    backgroundColor: _card,
                    onRefresh: _load,
                    child: _items.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 120),
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 36,
                                color: _muted.withValues(alpha: 0.7),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _error ?? 'No requests here.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                            itemCount: _items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return _WithdrawCard(
                                item: item,
                                rupee: _rupee(item.amount),
                                busy: _busyId == item.id,
                                onCopy: _copy,
                                onWithdraw: () => _act(item, 'complete'),
                                onReject: () => _act(item, 'reject'),
                                onEditReceipt: () => _replaceReceipt(item),
                                onViewReceipt: item.receiptUrl.isEmpty
                                    ? null
                                    : () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                WithdrawPaymentProcessedView(
                                              item: item,
                                            ),
                                          ),
                                        );
                                      },
                              );
                            },
                          ),
                  ),
          ),
          if (_error != null && _items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFFF8A80)),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2FCB71) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF07110A) : const Color(0xFF8B95A1),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _WithdrawCard extends StatelessWidget {
  const _WithdrawCard({
    required this.item,
    required this.rupee,
    required this.busy,
    required this.onCopy,
    required this.onWithdraw,
    required this.onReject,
    required this.onEditReceipt,
    this.onViewReceipt,
  });

  final WithdrawRequestItem item;
  final String rupee;
  final bool busy;
  final void Function(String label, String value) onCopy;
  final VoidCallback onWithdraw;
  final VoidCallback onReject;
  final VoidCallback onEditReceipt;
  final VoidCallback? onViewReceipt;

  static const Color _cream = Color(0xFFF4F1EA);
  static const Color _muted = Color(0xFF8B95A1);
  static const Color _line = Color(0xFF2A323C);
  static const Color _green = Color(0xFF2FCB71);

  bool get _canAct =>
      item.status == 'pending' || item.status == 'approved';

  String get _statusLabel {
    switch (item.status) {
      case 'completed':
        return 'Withdrawn';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  Color get _statusColor {
    switch (item.status) {
      case 'completed':
        return _green;
      case 'rejected':
        return const Color(0xFFEF6B6B);
      default:
        return const Color(0xFFE2C48A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone =
        item.phoneNumber.isNotEmpty ? item.phoneNumber : item.username;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF171C23),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  phone,
                  style: const TextStyle(
                    color: _cream,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '₹$rupee',
            style: const TextStyle(
              color: _cream,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: -0.6,
            ),
          ),
          if (item.userName.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.userName.trim(),
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            decoration: BoxDecoration(
              color: const Color(0xFF10141A),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _CopyRow(
                  label: 'A/C',
                  value: item.accountNumber,
                  onCopy: () => onCopy('Account number', item.accountNumber),
                ),
                _CopyRow(
                  label: 'IFSC',
                  value: item.ifsc,
                  onCopy: () => onCopy('IFSC', item.ifsc),
                ),
                _CopyRow(
                  label: 'UPI',
                  value: item.upiId,
                  onCopy: () => onCopy('UPI ID', item.upiId),
                ),
              ],
            ),
          ),
          if (item.status == 'completed' && item.receiptUrl.isNotEmpty) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: onViewReceipt,
              borderRadius: BorderRadius.circular(14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item.receiptUrl,
                      height: 64,
                      width: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 64,
                        width: 64,
                        color: const Color(0xFF10141A),
                        child: const Icon(
                          Icons.image_outlined,
                          color: _muted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Payment screenshot',
                      style: TextStyle(
                        color: _cream,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: busy ? null : onEditReceipt,
                    child: const Text(
                      'Edit image',
                      style: TextStyle(
                        color: _green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (item.status == 'completed') ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: busy ? null : onEditReceipt,
              icon: const Icon(Icons.add_photo_alternate_outlined, color: _green),
              label: const Text(
                'Add payment screenshot',
                style: TextStyle(color: _green, fontWeight: FontWeight.w700),
              ),
            ),
          ],
          if (_canAct) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: busy ? null : onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF6B6B),
                        side: const BorderSide(color: Color(0xFF5A3333)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 46,
                    child: FilledButton(
                      onPressed: busy ? null : onWithdraw,
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: const Color(0xFF07110A),
                        disabledBackgroundColor: _green.withValues(alpha: 0.45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF07110A),
                              ),
                            )
                          : const Text(
                              'Mark as withdraw',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final empty = value.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6F7A86),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              empty ? '—' : value,
              style: const TextStyle(
                color: Color(0xFFF4F1EA),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!empty)
            IconButton(
              onPressed: onCopy,
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.copy_rounded,
                size: 16,
                color: Color(0xFF8B95A1),
              ),
            ),
        ],
      ),
    );
  }
}
