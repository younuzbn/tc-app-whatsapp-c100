import 'dart:async';

import 'package:stacked/stacked.dart';

import '../../../services/admin_service.dart';
import '../../../services/game_schedule.dart';
import '../../../services/notification_service.dart';
import '../../../services/result_service.dart';
import '../../../services/session_service.dart';
import '../../../services/wallet_service.dart';
import 'game_chat_data.dart';

enum HomeCategory { draws, results, winning, myEntries }

enum HomeTab { digits, refer, wallet, profile }

class HomeViewModel extends BaseViewModel {
  HomeViewModel({required this.displayPhoneNumber}) {
    Future.microtask(refreshHome);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick += 1;
      notifyListeners();
      if (_tick % 20 == 0) {
        unawaited(_refreshPublishedResults());
      }
    });
  }

  final String displayPhoneNumber;
  final _walletService = const WalletService();
  final _notificationService = const NotificationService();
  final _adminService = const AdminService();
  final _resultService = const ResultService();

  bool _walletLoading = true;
  String _walletChipText = '';
  int _unreadNotifications = 0;
  HomeCategory _selectedCategory = HomeCategory.draws;
  HomeTab _selectedTab = HomeTab.digits;
  Timer? _clock;
  int _tick = 0;
  final Map<String, TimeAndCountSetting> _timeSettings = {};
  final Set<String> _resultPublishedSlots = {};
  final Map<String, int> _drawUnread = {};
  List<AppNotification> _unreadDrawAlerts = const [];

  /// Text next to the wallet icon (e.g. `₹500`, `—`, or empty while loading).
  String get walletChipText => _walletChipText;

  bool get walletLoading => _walletLoading;

  int get unreadNotifications => _unreadNotifications;

  HomeCategory get selectedCategory => _selectedCategory;

  HomeTab get selectedTab => _selectedTab;

  void selectTab(HomeTab tab) {
    if (_selectedTab == tab) return;
    _selectedTab = tab;
    notifyListeners();
    if (tab == HomeTab.digits) {
      refreshHome();
    }
  }

  Future<void> refreshHome() async {
    await Future.wait([
      refreshWallet(),
      refreshNotifications(),
      refreshDrawSchedules(),
    ]);
  }

  void selectCategory(HomeCategory category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> refreshNotifications() async {
    if (SessionService.isAdmin) {
      _unreadNotifications = 0;
      _drawUnread.clear();
      _unreadDrawAlerts = const [];
      notifyListeners();
      return;
    }
    try {
      final result = await _notificationService.list();
      _unreadNotifications = result.unread;
      _unreadDrawAlerts = result.items
          .where(
            (item) =>
                !item.read &&
                item.timeSlot != null &&
                item.timeSlot!.isNotEmpty &&
                (item.type == 'result' || item.type == 'win'),
          )
          .toList();
      _drawUnread
        ..clear()
        ..addEntries(
          _unreadDrawAlerts.fold<Map<String, int>>({}, (counts, item) {
            final key = item.timeSlot!.toLowerCase();
            counts[key] = (counts[key] ?? 0) + 1;
            return counts;
          }).entries,
        );
    } catch (_) {
      _unreadNotifications = await _notificationService.unreadCount();
    }
    notifyListeners();
  }

  int drawUnreadCount(GameChatData data) =>
      _drawUnread[data.timeSlot.toLowerCase()] ?? 0;

  Future<void> markDrawAlertsSeen(String timeSlot) async {
    final key = timeSlot.toLowerCase();
    final ids = _unreadDrawAlerts
        .where((item) => item.timeSlot?.toLowerCase() == key)
        .map((item) => item.id)
        .toList();
    if (ids.isEmpty) return;
    for (final id in ids) {
      try {
        await _notificationService.markRead(id);
      } catch (_) {}
    }
    await refreshNotifications();
  }

  Future<void> refreshWallet() async {
    _walletLoading = true;
    _walletChipText = '';
    notifyListeners();
    try {
      if (SessionService.isAdmin) {
        _walletChipText = '—';
      } else {
        final balance = await _walletService.fetchBalance();
        if (balance == null) {
          _walletChipText = '—';
        } else {
          _walletChipText = '₹${_fmtRupee(balance)}';
        }
      }
    } catch (_) {
      _walletChipText = '—';
    } finally {
      _walletLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDrawSchedules() async {
    try {
      final items = await _adminService.getTimeAndCountSettings();
      _timeSettings
        ..clear()
        ..addEntries(
          items.map(
            (item) => MapEntry(item.timeSlot.toLowerCase(), item),
          ),
        );
    } catch (_) {
      // Keep last known times if the request fails.
    }
    await _refreshPublishedResults();
    notifyListeners();
  }

  GameSchedule? scheduleFor(String timeSlot) {
    final setting = _timeSettings[timeSlot.toLowerCase()];
    if (setting == null) return null;
    return GameSchedule(
      openTime: setting.openTime,
      closeTime: setting.closeTime,
    );
  }

  bool isDrawClosed(GameChatData data) =>
      scheduleFor(data.timeSlot)?.isClosed == true;

  bool isDrawCountingDown(GameChatData data) {
    final schedule = scheduleFor(data.timeSlot);
    if (schedule == null || schedule.isClosed) return false;
    return schedule.closeCountdownLabel != null;
  }

  bool isResultPublished(GameChatData data) =>
      _resultPublishedSlots.contains(data.timeSlot.toLowerCase());

  String drawSnippet(GameChatData data) {
    final schedule = scheduleFor(data.timeSlot);
    if (schedule == null || !schedule.isClosed) {
      return data.snippet;
    }
    if (isResultPublished(data)) {
      return 'Result published';
    }
    return 'Entries closed';
  }

  String drawTimeLabel(GameChatData data) {
    final schedule = scheduleFor(data.timeSlot);
    if (schedule == null) return data.time;
    if (schedule.isClosed) return schedule.opensAtLabel;
    return schedule.closeCountdownLabel ?? data.time;
  }

  Future<void> _refreshPublishedResults() async {
    var changed = false;
    for (final game in gameChats) {
      final key = game.timeSlot.toLowerCase();
      final schedule = scheduleFor(game.timeSlot);
      if (schedule == null || !schedule.isClosed) {
        if (_resultPublishedSlots.remove(key)) changed = true;
        continue;
      }
      final date = schedule.closedSessionResultDate;
      if (date == null) continue;
      try {
        final result = await _resultService.getResultForDate(
          timeSlot: game.timeSlot,
          date: date,
        );
        final published = result != null;
        if (published) {
          if (_resultPublishedSlots.add(key)) changed = true;
        } else if (_resultPublishedSlots.remove(key)) {
          changed = true;
        }
      } catch (_) {
        // Keep previous published status on network errors.
      }
    }
    if (changed) notifyListeners();
  }

  String _fmtRupee(double value) {
    if (value.truncateToDouble() == value) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }
}
