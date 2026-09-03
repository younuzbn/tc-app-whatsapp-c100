import 'package:flutter/material.dart';

import '../../../services/sales_service.dart';
import '../../../services/wallet_service.dart';
import '../../theme/win_theme.dart';

class AdminCustomerChatView extends StatefulWidget {
  const AdminCustomerChatView({
    super.key,
    required this.customerId,
  });

  final String customerId;

  @override
  State<AdminCustomerChatView> createState() => _AdminCustomerChatViewState();
}

class _AdminCustomerChatViewState extends State<AdminCustomerChatView> {
  final _salesService = const SalesService();
  final _walletService = const WalletService();
  bool _loading = true;
  String? _error;
  String? _verifyingId;
  List<ConversationMessage> _messages = [];

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
      _messages = await _salesService.getCustomerConversation(widget.customerId);
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyTopup(WalletTopupMessage topup, {String action = 'verify'}) async {
    if (_verifyingId != null) return;
    setState(() => _verifyingId = topup.id);
    try {
      await _walletService.verifyAdminTopup(topup.id, action: action);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'reject'
                ? 'Add money request rejected'
                : 'Payment verified. Amount credited to deposit.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _verifyingId = null);
    }
  }

  void _openFullImage(BuildContext context, String imageUrl) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenImagePage(imageUrl: imageUrl);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.customerId)),
      backgroundColor: const Color(0xFFF2ECE4),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final chronoIndex = _messages.length - 1 - index;
                  final message = _messages[chronoIndex];
                  final date = message.sale?.createdDate ?? message.date;
                  final time = (message.sale?.placedAt ?? message.date)?.toLocal();
                  final timeLabel = time == null
                      ? ''
                      : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  final dateLabel = WinTheme.monthDay(date);
                  final stamp = [
                    if (dateLabel.isNotEmpty) dateLabel,
                    if (timeLabel.isNotEmpty) timeLabel,
                  ].join(' · ');
                  final isAdminMessage = message.messageFrom == 'admin';
                  final previous =
                      chronoIndex > 0 ? _messages[chronoIndex - 1] : null;
                  final previousDate = previous?.sale?.createdDate ?? previous?.date;
                  final showDateChip = previous == null ||
                      !WinTheme.sameDay(date, previousDate);

                  return Column(
                    children: [
                      if (showDateChip)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD6D3D1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                WinTheme.dayChip(date),
                                style: const TextStyle(
                                  color: Color(0xFF44403C),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Align(
                      alignment: isAdminMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 280),
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                        decoration: BoxDecoration(
                          color: isAdminMessage
                              ? const Color(0xFFD9FDD3)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.messageType == 'sale_ack' &&
                                message.saleAck != null) ...[
                              Text(
                                message.saleAck!.message,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ] else if (message.messageType == 'result' &&
                                message.resultMessage != null) ...[
                              const Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0B8F78),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message.resultMessage!.message,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ] else if (message.messageType == 'winning' &&
                                message.winning != null) ...[
                              const Text(
                                'You got a winning',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0B8F78),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${WinTheme.lskLabel(message.winning!.lsk)} - ${message.winning!.number} - ${message.winning!.count} - ₹${WinTheme.rupee(message.winning!.winAmount)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ] else if (message.messageType == 'wallet_topup' &&
                                message.walletTopup != null) ...[
                              Text(
                                message.walletTopup!.isPending
                                    ? 'Add money request'
                                    : message.walletTopup!.isRejected
                                    ? 'Add money rejected'
                                    : 'Wallet top-up',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0B8F78),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Amount ₹${message.walletTopup!.amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                message.walletTopup!.userStatus,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: message.walletTopup!.isCredited
                                      ? const Color(0xFF0B8F78)
                                      : message.walletTopup!.isRejected
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFFD97706),
                                ),
                              ),
                              if (message.walletTopup!.screenshotUrl.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _openFullImage(
                                      context,
                                      message.walletTopup!.screenshotUrl,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Ink(
                                      height: 160,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: const Color(0xFFE5E7EB),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.network(
                                              message.walletTopup!.screenshotUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) =>
                                                  const Center(
                                                child: Text(
                                                  'Screenshot unavailable',
                                                  style: TextStyle(fontSize: 11),
                                                ),
                                              ),
                                            ),
                                            const Positioned(
                                              right: 6,
                                              bottom: 6,
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius:
                                                      BorderRadius.all(
                                                    Radius.circular(6),
                                                  ),
                                                ),
                                                child: Padding(
                                                  padding: EdgeInsets.all(4),
                                                  child: Icon(
                                                    Icons.fullscreen,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (message.walletTopup!.isPending) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: _verifyingId == message.walletTopup!.id
                                        ? null
                                        : () => _verifyTopup(message.walletTopup!),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF0B8F78),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: _verifyingId == message.walletTopup!.id
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Confirm as payment verified'),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _verifyingId == message.walletTopup!.id
                                      ? null
                                      : () => _verifyTopup(
                                            message.walletTopup!,
                                            action: 'reject',
                                          ),
                                  child: const Text('Reject request'),
                                ),
                              ],
                            ] else if (message.sale != null) ...[
                              Text(
                                '${message.sale!.timeSlot.toUpperCase()} ${message.sale!.lsk} ${message.sale!.number} x ${message.sale!.count}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sale date ${WinTheme.monthDay(message.sale!.createdDate ?? message.date)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Bill ${message.sale!.billNumber}  Amount ₹${message.sale!.damount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                            if (stamp.isNotEmpty ||
                                message.messageType == 'sale') ...[
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (stamp.isNotEmpty)
                                      Text(
                                        stamp,
                                        style: const TextStyle(
                                          color: Color(0xFF6B7280),
                                          fontSize: 10,
                                        ),
                                      ),
                                    if (message.messageType == 'sale') ...[
                                      if (stamp.isNotEmpty)
                                        const SizedBox(width: 4),
                                      Icon(
                                        Icons.done_all,
                                        size: 14,
                                        color: message.sale?.isConfirmed == true
                                            ? const Color(0xFF53BDEB)
                                            : const Color(0xFF6B7280),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

class _FullScreenImagePage extends StatelessWidget {
  const _FullScreenImagePage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Text(
                      'Unable to load image',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
