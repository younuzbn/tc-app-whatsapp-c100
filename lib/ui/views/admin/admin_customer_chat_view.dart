import 'package:flutter/material.dart';

import '../../../services/sales_service.dart';
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
  final _scroll = ScrollController();
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  DateTime? _nextBefore;
  String? _error;
  List<ConversationMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadNewest();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients || _loading || _loadingMore || !_hasMore) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 280) {
      _loadOlder();
    }
  }

  Future<void> _loadNewest() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _salesService.getCustomerConversation(widget.customerId);
      if (!mounted) return;
      setState(() {
        _messages = page.messages;
        _hasMore = page.hasMore;
        _nextBefore = page.nextBefore;
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

  Future<void> _loadOlder() async {
    if (_loadingMore || !_hasMore) return;
    final before = _nextBefore;
    if (before == null) {
      setState(() => _hasMore = false);
      return;
    }
    setState(() => _loadingMore = true);
    try {
      final page = await _salesService.getCustomerConversation(
        widget.customerId,
        before: before,
      );
      if (!mounted) return;
      final seen = _messages.map((item) => item.id).toSet();
      final older = page.messages.where((item) => seen.add(item.id)).toList();
      final sameCursor = page.nextBefore != null &&
          _nextBefore != null &&
          page.nextBefore!.isAtSameMomentAs(_nextBefore!);
      setState(() {
        _messages = [...older, ..._messages];
        _hasMore = page.hasMore && older.isNotEmpty && !sameCursor;
        _nextBefore = page.nextBefore;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
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
          : RefreshIndicator(
              onRefresh: _loadNewest,
              child: ListView.builder(
                controller: _scroll,
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount:
                    _messages.length + (_hasMore || _loadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _messages.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  final chronoIndex = _messages.length - 1 - index;
                  final message = _messages[chronoIndex];
                  final date = message.sale?.createdDate ?? message.date;
                  final time =
                      (message.sale?.placedAt ?? message.date)?.toLocal();
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
                  final previousDate =
                      previous?.sale?.createdDate ?? previous?.date;
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
                                            color:
                                                message.sale?.isConfirmed ==
                                                    true
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
