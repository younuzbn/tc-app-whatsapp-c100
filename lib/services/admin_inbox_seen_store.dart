import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'sales_service.dart';
import 'wallet_service.dart';

class AdminInboxSeenStore {
  AdminInboxSeenStore._();
  static final AdminInboxSeenStore instance = AdminInboxSeenStore._();

  static const _channel = MethodChannel('win_app/session');

  final Map<String, String> _entryStamps = {};
  final Map<String, int> _seenCounts = {};
  final Set<String> _withdrawIds = {};
  bool _withdrawalsVisited = false;
  DateTime? _complaintsSeenAt;
  int _localEdits = 0;
  bool _hydrated = false;
  Future<void>? _hydrateFuture;
  Future<void> _writeChain = Future<void>.value();

  DateTime? get complaintsSeenAt => _complaintsSeenAt;

  Future<void> restore() {
    return _hydrateFuture ??= _hydrate();
  }

  void markComplaintsSeen() {
    _localEdits++;
    _complaintsSeenAt = DateTime.now().toUtc();
    _scheduleWrite();
  }

  String _entryStamp(CustomerChatSummary chat) {
    final ms = chat.lastCreatedDate?.toUtc().millisecondsSinceEpoch ?? 0;
    return '$ms:${chat.messageCount}';
  }

  bool isEntryUnread(CustomerChatSummary chat) {
    if (chat.messageCount <= 0) return false;
    return _entryStamps[chat.customerId] != _entryStamp(chat);
  }

  int unreadEntryCount(CustomerChatSummary chat) {
    if (!isEntryUnread(chat)) return 0;
    final seen = _seenCounts[chat.customerId] ?? 0;
    final delta = chat.messageCount - seen;
    if (delta > 0) return delta;
    return 1;
  }

  int unreadEntries(List<CustomerChatSummary> chats) {
    var count = 0;
    for (final chat in chats) {
      if (isEntryUnread(chat)) count++;
    }
    return count;
  }

  void markChatSeen(CustomerChatSummary chat) {
    _localEdits++;
    _entryStamps[chat.customerId] = _entryStamp(chat);
    _seenCounts[chat.customerId] = chat.messageCount;
    _scheduleWrite();
  }

  int unreadWithdrawals(List<WithdrawRequestItem> items) {
    final pending = items.where(_isPending).toList();
    if (!_withdrawalsVisited) return pending.length;
    return pending.where((item) => !_withdrawIds.contains(item.id)).length;
  }

  void markWithdrawalsSeen(List<WithdrawRequestItem> items) {
    _localEdits++;
    _withdrawalsVisited = true;
    _withdrawIds
      ..clear()
      ..addAll(items.where(_isPending).map((item) => item.id));
    _scheduleWrite();
  }

  bool _isPending(WithdrawRequestItem item) =>
      item.status == 'pending' || item.status == 'approved';

  Future<void> _hydrate() async {
    Map<String, dynamic>? data;
    try {
      final raw = await _channel.invokeMethod<dynamic>('loadAdminInbox');
      final text = raw?.toString() ?? '';
      if (text.isNotEmpty) {
        final decoded = jsonDecode(text);
        if (decoded is Map) {
          data = decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      }
    } catch (_) {}
    if (_localEdits == 0 && data != null) {
      _apply(data);
    }
    _hydrated = true;
  }

  void _apply(Map<String, dynamic> data) {
    final stamps = data['entryStamps'];
    if (stamps is Map) {
      _entryStamps
        ..clear()
        ..addAll(
          stamps.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ),
        );
    }
    final counts = data['seenCounts'];
    if (counts is Map) {
      _seenCounts.clear();
      for (final entry in counts.entries) {
        final count = int.tryParse(entry.value.toString());
        if (count != null) _seenCounts[entry.key.toString()] = count;
      }
    }
    final withdrawIds = data['withdrawIds'];
    if (withdrawIds is List) {
      _withdrawIds
        ..clear()
        ..addAll(withdrawIds.map((id) => id.toString()).where((id) => id.isNotEmpty));
    }
    _withdrawalsVisited = data['withdrawalsVisited'] == true;
    final complaints = data['complaintsSeenAt']?.toString() ?? '';
    _complaintsSeenAt = complaints.isEmpty ? null : DateTime.tryParse(complaints);
  }

  void _scheduleWrite() {
    _writeChain = _writeChain.then((_) async {
      if (!_hydrated) await restore();
      try {
        await _channel.invokeMethod<void>('saveAdminInbox', {
          'data': jsonEncode({
            'entryStamps': _entryStamps,
            'seenCounts': _seenCounts,
            'withdrawIds': _withdrawIds.toList(),
            'withdrawalsVisited': _withdrawalsVisited,
            'complaintsSeenAt': _complaintsSeenAt?.toUtc().toIso8601String(),
          }),
        });
      } catch (_) {}
    });
  }
}
