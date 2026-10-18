import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/wallet_service.dart';
import '../../theme/win_theme.dart';

class AdminSuccessfulPaymentsView extends StatefulWidget {
  const AdminSuccessfulPaymentsView({super.key});

  @override
  State<AdminSuccessfulPaymentsView> createState() =>
      _AdminSuccessfulPaymentsViewState();
}

class _AdminSuccessfulPaymentsViewState
    extends State<AdminSuccessfulPaymentsView> {
  static const _bg = Color(0xFF07090C);
  static const _card = Color(0xFF171C23);
  static const _muted = Color(0xFF8B95A1);
  static const _cream = Color(0xFFF4F1EA);
  static const _green = Color(0xFF2FCB71);

  final _wallet = const WalletService();
  final _scroll = ScrollController();
  final List<SuccessfulPaymentItem> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;

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
      final page = await _wallet.fetchSuccessfulPayments();
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
      final page = await _wallet.fetchSuccessfulPayments(before: _items.last.id);
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

  String _when(DateTime? d) {
    if (d == null) return '';
    final local = d.toLocal();
    final hour = local.hour > 12
        ? local.hour - 12
        : (local.hour == 0 ? 12 : local.hour);
    final ampm = local.hour >= 12 ? 'pm' : 'am';
    return '${WinTheme.monthDay(local)} · $hour:${local.minute.toString().padLeft(2, '0')} $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _cream,
        title: const Text('Successful payments'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            )
          : RefreshIndicator(
              color: _green,
              onRefresh: _load,
              child: ListView.separated(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                itemCount: _items.isEmpty
                    ? 1
                    : _items.length + (_loadingMore ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (_items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No successful payments yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted),
                      ),
                    );
                  }
                  if (index >= _items.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(color: _green),
                      ),
                    );
                  }
                  final item = _items[index];
                  return _PaymentCard(
                    item: item,
                    when: _when(item.paidAt),
                    onCopy: _copy,
                  );
                },
              ),
            ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.item,
    required this.when,
    required this.onCopy,
  });

  final SuccessfulPaymentItem item;
  final String when;
  final void Function(String label, String value) onCopy;

  static const _cream = Color(0xFFF4F1EA);
  static const _muted = Color(0xFF8B95A1);
  static const _green = Color(0xFF2FCB71);

  Widget _row(String label, String value) {
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
        border: Border.all(color: const Color(0x554ADE80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: _green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: const TextStyle(
                        color: _cream,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    if (when.isNotEmpty)
                      Text(
                        when,
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Text(
                '₹${WinTheme.rupee(item.amount)}',
                style: const TextStyle(
                  color: _green,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          _row('Phone', item.userPhone),
          _row('Name', item.userName),
          _row('Order', item.orderId),
          _row('UTI', item.uti.startsWith('AUTO_') ? '' : item.uti),
          _row('Via', item.providerLabel),
        ],
      ),
    );
  }
}
