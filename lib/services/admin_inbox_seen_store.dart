import 'sales_service.dart';
import 'wallet_service.dart';

class AdminInboxSeenStore {
  AdminInboxSeenStore._();
  static final AdminInboxSeenStore instance = AdminInboxSeenStore._();

  final Map<String, String> _entryStamps = {};
  final Set<String> _withdrawIds = {};
  bool _withdrawalsVisited = false;

  String _entryStamp(CustomerChatSummary chat) {
    final ms = chat.lastCreatedDate?.toUtc().millisecondsSinceEpoch ?? 0;
    return '$ms:${chat.messageCount}:${chat.lastMessage}';
  }

  bool isEntryUnread(CustomerChatSummary chat) {
    if (chat.messageCount <= 0) return false;
    return _entryStamps[chat.customerId] != _entryStamp(chat);
  }

  int unreadEntries(List<CustomerChatSummary> chats) {
    var count = 0;
    for (final chat in chats) {
      if (isEntryUnread(chat)) count++;
    }
    return count;
  }

  void markChatSeen(CustomerChatSummary chat) {
    _entryStamps[chat.customerId] = _entryStamp(chat);
  }

  int unreadWithdrawals(List<WithdrawRequestItem> items) {
    final pending = items.where(_isPending).toList();
    if (!_withdrawalsVisited) return pending.length;
    return pending.where((item) => !_withdrawIds.contains(item.id)).length;
  }

  void markWithdrawalsSeen(List<WithdrawRequestItem> items) {
    _withdrawalsVisited = true;
    _withdrawIds
      ..clear()
      ..addAll(items.where(_isPending).map((item) => item.id));
  }

  bool _isPending(WithdrawRequestItem item) =>
      item.status == 'pending' || item.status == 'approved';
}
