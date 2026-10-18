import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'admin_inbox_seen_store.dart';
import 'notification_service.dart';
import 'page_content_service.dart';
import 'sales_service.dart';
import 'session_service.dart';
import 'share_media_cache.dart';
import 'support_service.dart';
import 'wallet_service.dart';

class OsAppBadgeService with WidgetsBindingObserver {
  OsAppBadgeService._();

  static final OsAppBadgeService instance = OsAppBadgeService._();
  static const _channel = MethodChannel('win_app/session');
  static const _userAlertTypes = ['win', 'result', 'withdraw_success'];

  final _notifications = const NotificationService();
  final _sales = const SalesService();
  final _wallet = const WalletService();
  final _support = const SupportService();

  Timer? _timer;
  bool _started = false;
  int _lastCount = -1;

  Future<void> start() async {
    if (_started) {
      await refresh();
      return;
    }
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    try {
      await _channel.invokeMethod<void>('requestNotificationPermission');
    } catch (_) {}
    await refresh();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(refresh());
    });
  }

  Future<void> stop() async {
    _started = false;
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  Future<void> clear() async {
    _lastCount = 0;
    await _setNative(count: 0, title: '', text: '', alert: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refresh());
      unawaited(ShareMediaCache.instance.prefetch());
      unawaited(PageContentService.instance.prefetch());
    }
  }

  Future<void> applyCount(
    int count, {
    required String title,
    required String text,
  }) async {
    if (!SessionService.isLoggedIn) {
      await clear();
      return;
    }
    final next = count < 0 ? 0 : count;
    final alert = _lastCount >= 0 && next > _lastCount;
    if (next == _lastCount) return;
    _lastCount = next;
    await _setNative(count: next, title: title, text: text, alert: alert);
  }

  Future<void> refresh() async {
    if (!SessionService.isLoggedIn) {
      await clear();
      return;
    }
    if (SessionService.isAdmin) {
      final count = await _adminCount();
      await applyCount(
        count,
        title: 'Win App Admin',
        text: count <= 0
            ? ''
            : count == 1
                ? '1 new admin alert'
                : '$count new admin alerts',
      );
      return;
    }
    final count = await _notifications.unreadCount(types: _userAlertTypes);
    await applyCount(
      count,
      title: 'Win App',
      text: count <= 0
          ? ''
          : count == 1
              ? 'New result or winning'
              : '$count new results or winnings',
    );
  }

  Future<int> _adminCount() async {
    final seen = AdminInboxSeenStore.instance;
    await seen.restore();
    final results = await Future.wait<int>([
      _safe(
        () async => seen.unreadEntries(await _sales.getMobileCustomerChats()),
      ),
      _safe(
        () async => seen.unreadWithdrawals(
          await _wallet.fetchAdminWithdrawRequests(status: 'processing'),
        ),
      ),
      _safe(
        () => _support.fetchAdminUnreadCount(since: seen.complaintsSeenAt),
      ),
      _safe(_wallet.fetchOpenDisputeCount),
      _safe(_notifications.unreadCount),
    ]);
    return results.fold<int>(0, (sum, value) => sum + value);
  }

  Future<int> _safe(Future<int> Function() load) async {
    try {
      return await load();
    } catch (_) {
      return 0;
    }
  }

  Future<void> _setNative({
    required int count,
    required String title,
    required String text,
    required bool alert,
  }) async {
    try {
      await _channel.invokeMethod<void>('setAppBadge', {
        'count': count,
        'title': title,
        'text': text,
        'alert': alert,
      });
    } catch (_) {}
  }
}

class OsAppBadgeHost extends StatefulWidget {
  const OsAppBadgeHost({super.key, required this.child});

  final Widget child;

  @override
  State<OsAppBadgeHost> createState() => _OsAppBadgeHostState();
}

class _OsAppBadgeHostState extends State<OsAppBadgeHost> {
  @override
  void initState() {
    super.initState();
    unawaited(OsAppBadgeService.instance.start());
    unawaited(ShareMediaCache.instance.prefetch());
    unawaited(PageContentService.instance.prefetch());
  }

  @override
  void dispose() {
    unawaited(OsAppBadgeService.instance.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
