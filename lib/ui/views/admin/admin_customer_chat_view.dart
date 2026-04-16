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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.customerId)),
      backgroundColor: const Color(0xFFF2ECE4),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView.builder(
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
    );
  }
}
