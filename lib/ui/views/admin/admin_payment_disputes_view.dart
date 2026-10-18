import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/app_config.dart';
import '../../../services/wallet_service.dart';

class AdminPaymentDisputesView extends StatefulWidget {
  const AdminPaymentDisputesView({super.key});

  @override
  State<AdminPaymentDisputesView> createState() =>
      _AdminPaymentDisputesViewState();
}

class _AdminPaymentDisputesViewState extends State<AdminPaymentDisputesView> {
  static const _bg = Color(0xFF07090C);
  static const _card = Color(0xFF171C23);
  static const _muted = Color(0xFF8B95A1);
  static const _cream = Color(0xFFF4F1EA);
  static const _green = Color(0xFF2FCB71);

  final _wallet = const WalletService();
  final _scroll = ScrollController();
  final List<PaymentDisputeItem> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 240) {
        _loadMore();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _wallet.fetchPaymentDisputes();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore || _items.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _wallet.fetchPaymentDisputes(before: _items.last.id);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
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
            child: const Text('Back', style: TextStyle(color: _muted)),
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

  Future<void> _credit(PaymentDisputeItem item) async {
    final amount = '₹${item.amount.toStringAsFixed(0)}';
    final ok = await _confirm(
      title: 'Add to wallet?',
      body: 'Add $amount to ${item.displayName}\'s wallet?',
      confirmLabel: 'Add to wallet',
      confirmColor: _green,
    );
    if (!ok || !mounted) return;
    setState(() => _busyId = item.id);
    try {
      final message = await _wallet.creditDisputedPayment(item.id);
      if (!mounted) return;
      setState(() => _items.removeWhere((row) => row.id == item.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: _card, content: Text(message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _card,
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _cancel(PaymentDisputeItem item) async {
    final ok = await _confirm(
      title: 'Cancel this dispute?',
      body:
          'Cancel if this looks fake. The user will be notified and can send the dispute again.',
      confirmLabel: 'Cancel dispute',
      confirmColor: const Color(0xFFEF6B6B),
    );
    if (!ok || !mounted) return;
    setState(() => _busyId = item.id);
    try {
      await _wallet.updatePaymentDispute(item.id, status: 'dismissed');
      if (!mounted) return;
      setState(() => _items.removeWhere((row) => row.id == item.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: _card,
          content: Text('Dispute cancelled. User can send it again.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _card,
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  String _imageUrl(String path) {
    if (path.startsWith('http')) return path;
    return '${AppConfig.apiBaseUrl}$path';
  }

  Future<void> _copy(String label, String value) async {
    if (value.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value.trim()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _card,
        content: Text('$label copied', style: const TextStyle(color: _cream)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _cream,
        title: const Text('Payment disputes'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                itemCount: _items.isEmpty
                    ? 1
                    : _items.length + (_loadingMore ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  if (_items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No new disputes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted),
                      ),
                    );
                  }
                  if (index >= _items.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final item = _items[index];
                  return _DisputeAlertCard(
                    item: item,
                    busy: _busyId == item.id,
                    imageUrl: _imageUrl,
                    onCopy: _copy,
                    onAddToWallet: () => _credit(item),
                    onCancel: () => _cancel(item),
                  );
                },
              ),
            ),
    );
  }
}

class _DisputeAlertCard extends StatelessWidget {
  const _DisputeAlertCard({
    required this.item,
    required this.busy,
    required this.imageUrl,
    required this.onCopy,
    required this.onAddToWallet,
    required this.onCancel,
  });

  final PaymentDisputeItem item;
  final bool busy;
  final String Function(String path) imageUrl;
  final void Function(String label, String value) onCopy;
  final VoidCallback onAddToWallet;
  final VoidCallback onCancel;

  static const _cream = Color(0xFFF4F1EA);
  static const _muted = Color(0xFF8B95A1);
  static const _line = Color(0xFF2A323C);
  static const _green = Color(0xFF2FCB71);

  Widget _detail(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onLongPress: () => onCopy(label, value),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: Text(
                label,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(color: _cream, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF171C23),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x55F87171)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x33F87171),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'NEW DISPUTE',
                  style: TextStyle(
                    color: Color(0xFFF87171),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '₹${item.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.displayName,
            style: const TextStyle(
              color: _cream,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          _detail('Phone', item.userPhone),
          _detail('User', item.username),
          _detail('Status', item.paymentStatus),
          _detail('Reason', item.reasonLabel),
          if (item.note.isNotEmpty) _detail('Note', item.note),
          if (item.orderId.isNotEmpty) _detail('Order', item.orderId),
          if (item.images.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: item.images.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, imageIndex) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl(item.images[imageIndex]),
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: _line),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : onAddToWallet,
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: const Color(0xFF07110A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(busy ? 'Please wait…' : 'Add to wallet'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF87171),
                    side: const BorderSide(color: Color(0x66F87171)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
