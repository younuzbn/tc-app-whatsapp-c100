import 'package:flutter/material.dart';

import '../../../services/sales_service.dart';

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
  bool _loading = true;
  String? _error;
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
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final date = message.date;
                  final timeLabel = date == null
                      ? ''
                      : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                  final isAdminMessage = message.messageFrom == 'admin';

                  return Padding(
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
                            if (message.messageType == 'result' &&
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
                            ] else if (message.messageType == 'wallet_topup' &&
                                message.walletTopup != null) ...[
                              const Text(
                                'Wallet top-up',
                                style: TextStyle(
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
                              const SizedBox(height: 2),
                              Text(
                                'UPI Transaction ID ${message.walletTopup!.uti}',
                                style: const TextStyle(fontSize: 12),
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
                                'Bill ${message.sale!.billNumber}  Amount ₹${message.sale!.damount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                            if (timeLabel.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  timeLabel,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
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
