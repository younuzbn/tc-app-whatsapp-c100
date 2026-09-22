import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/admin_inbox_seen_store.dart';
import '../../../services/sales_service.dart';
import '../../theme/win_theme.dart';
import '../home/game_chat_data.dart';
import 'admin_customer_chat_view.dart';

class AdminEntriesView extends StatefulWidget {
  const AdminEntriesView({super.key});

  @override
  State<AdminEntriesView> createState() => _AdminEntriesViewState();
}

class _AdminEntriesViewState extends State<AdminEntriesView> {
  static const Color _bg = Color(0xFF0B141A);
  static const Color _surface = Color(0xFF111B21);
  static const Color _line = Color(0xFF1F2C34);
  static const Color _muted = Color(0xFF8696A0);
  static const Color _green = Color(0xFF25D366);
  static const Color _cream = Color(0xFFE9EDEF);

  static const List<_GameFilter> _games = [
    _GameFilter(timeSlot: 'all', label: 'All games'),
    _GameFilter(timeSlot: '1pm', label: 'Dear 1 PM'),
    _GameFilter(timeSlot: '3pm', label: 'Kerala 3 PM'),
    _GameFilter(timeSlot: '6pm', label: 'Dear 6 PM'),
    _GameFilter(timeSlot: '8pm', label: 'Dear 8 PM'),
  ];

  final _salesService = const SalesService();
  final _seen = AdminInboxSeenStore.instance;
  Timer? _pollTimer;
  String _timeSlot = 'all';
  bool _loading = true;
  String? _error;
  List<CustomerChatSummary> _chats = [];

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      unawaited(_load(silent: true));
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final chats = await _salesService.getMobileCustomerChats(
        timeSlot: _timeSlot,
      );
      final filtered = _timeSlot == 'all'
          ? chats
          : chats
              .where((chat) => chat.timeSlot.toLowerCase() == _timeSlot)
              .toList();
      if (!mounted) return;
      setState(() {
        _chats = filtered;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (!silent) {
          _error = error.toString().replaceFirst('Exception: ', '');
        }
        _loading = false;
      });
    }
  }

  String _displayPhone(String customerId) {
    if (customerId.startsWith('91') && customerId.length == 12) {
      return customerId.substring(2);
    }
    return customerId;
  }

  String _timeLabel(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _gameLabel(String timeSlot) {
    final slot = timeSlot.toLowerCase();
    if (slot == 'wallet') return 'Wallet';
    for (final game in gameChats) {
      if (game.timeSlot == slot) return game.name;
    }
    return WinTheme.drawLabel(slot);
  }

  Future<void> _openChat(CustomerChatSummary chat) async {
    _seen.markChatSeen(chat);
    if (mounted) setState(() {});
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminCustomerChatView(customerId: chat.customerId),
      ),
    );
    if (!mounted) return;
    await _load(silent: true);
    CustomerChatSummary? updated;
    for (final item in _chats) {
      if (item.customerId == chat.customerId) {
        updated = item;
        break;
      }
    }
    _seen.markChatSeen(updated ?? chat);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return WinStatusBar(
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          foregroundColor: _cream,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Entries',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: DropdownButtonFormField<String>(
                value: _timeSlot,
                isExpanded: true,
                dropdownColor: _surface,
                iconEnabledColor: _muted,
                style: const TextStyle(
                  color: _cream,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _surface,
                  labelText: 'Game',
                  labelStyle: const TextStyle(color: _muted),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _green),
                  ),
                ),
                items: [
                  for (final game in _games)
                    DropdownMenuItem<String>(
                      value: game.timeSlot,
                      child: Text(game.label),
                    ),
                ],
                onChanged: (slot) {
                  if (slot == null || slot == _timeSlot) return;
                  setState(() => _timeSlot = slot);
                  _load();
                },
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      color: _green,
                      onRefresh: _load,
                      child: _chats.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const SizedBox(height: 80),
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 40,
                                  color: _muted.withValues(alpha: 0.7),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _error ?? 'No sale chats yet.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _error != null
                                        ? Colors.redAccent
                                        : _muted,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _chats.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: _line,
                              ),
                              itemBuilder: (context, index) {
                                final chat = _chats[index];
                                final unseenCount = _seen.unreadEntryCount(chat);
                                return ListTile(
                                  onTap: () => _openChat(chat),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: const Color(0xFF008069),
                                    child: Text(
                                      _displayPhone(chat.customerId).isEmpty
                                          ? '?'
                                          : _displayPhone(
                                              chat.customerId,
                                            ).substring(0, 1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    _displayPhone(chat.customerId),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${_gameLabel(chat.timeSlot)} · ${chat.lastMessage}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _timeLabel(chat.lastCreatedDate),
                                        style: const TextStyle(
                                          color: _muted,
                                          fontSize: 11,
                                        ),
                                      ),
                                      if (unseenCount > 0) ...[
                                        const SizedBox(height: 4),
                                        CircleAvatar(
                                          radius: 10,
                                          backgroundColor: _green,
                                          child: Text(
                                            unseenCount > 99
                                                ? '99+'
                                                : '$unseenCount',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
            ),
            if (_error != null && _chats.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GameFilter {
  const _GameFilter({required this.timeSlot, required this.label});

  final String timeSlot;
  final String label;
}
