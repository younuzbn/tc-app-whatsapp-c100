import 'package:flutter/material.dart';

import '../../../services/notification_service.dart';
import '../../theme/win_theme.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final _service = const NotificationService();
  bool _loading = true;
  String? _error;
  List<AppNotification> _items = [];
  int _unread = 0;

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
      final result = await _service.list();
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _unread = result.unread;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _markAll() async {
    await _service.markAllRead();
    await _load();
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'win':
        return Icons.emoji_events_rounded;
      case 'result':
        return Icons.assignment_turned_in_rounded;
      case 'welcome_bonus':
        return Icons.account_balance_wallet_rounded;
      case 'referral_reward':
        return Icons.card_giftcard_rounded;
      case 'draw_live':
        return Icons.sports_esports_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'win':
        return WinTheme.gold;
      case 'referral_reward':
        return WinTheme.blue;
      default:
        return WinTheme.green;
    }
  }

  String _timeLabel(DateTime? d) {
    if (d == null) return '';
    final local = d.toLocal();
    final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final ampm = local.hour >= 12 ? 'pm' : 'am';
    return '${local.day} ${_month(local.month)} · $hour:${local.minute.toString().padLeft(2, '0')} $ampm';
  }

  String _month(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WinTheme.bg,
      appBar: AppBar(
        backgroundColor: WinTheme.bg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          TextButton(
            onPressed: _unread == 0 ? null : _markAll,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: WinTheme.green))
          : RefreshIndicator(
              color: WinTheme.green,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (_unread > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '• $_unread unread notifications',
                        style: const TextStyle(color: WinTheme.green, fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  if (_items.isEmpty && _error == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text('No notifications yet.', style: TextStyle(color: WinTheme.muted)),
                      ),
                    ),
                  ..._items.map((item) {
                    final color = _colorFor(item.type);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!item.read)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 18, right: 8),
                              decoration: const BoxDecoration(
                                color: WinTheme.green,
                                shape: BoxShape.circle,
                              ),
                            )
                          else
                            const SizedBox(width: 16),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_iconFor(item.type), color: color, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.message,
                                  style: const TextStyle(color: WinTheme.muted, height: 1.3),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _timeLabel(item.createdAt),
                                  style: const TextStyle(color: WinTheme.muted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
