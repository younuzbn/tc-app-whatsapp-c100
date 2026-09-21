import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/admin_inbox_seen_store.dart';
import '../../../services/sales_service.dart';
import '../../../services/session_service.dart';
import '../../../services/wallet_service.dart';
import '../../theme/win_theme.dart';
import '../auth/phone_login/phone_login_view.dart';
import 'admin_account_summary_view.dart';
import 'admin_entries_view.dart';
import 'admin_game_chat_options_view.dart';
import 'admin_referral_codes_view.dart';
import 'admin_referral_tree_view.dart';
import 'admin_users_view.dart';
import 'admin_withdraw_requests_view.dart';

class AdminHomeView extends StatefulWidget {
  const AdminHomeView({super.key});

  @override
  State<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends State<AdminHomeView> {
  final _salesService = const SalesService();
  final _walletService = const WalletService();
  final _seen = AdminInboxSeenStore.instance;
  Timer? _pollTimer;
  bool _loading = true;
  String? _error;
  List<CustomerChatSummary> _customerChats = [];
  List<WithdrawRequestItem> _withdrawals = [];

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      unawaited(_load(silent: true));
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  String? _badge(int count) {
    if (count <= 0) return null;
    if (count > 99) return '99+';
    return '$count';
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final chats = await _salesService.getMobileCustomerChats();
      List<WithdrawRequestItem> withdrawals = const [];
      try {
        withdrawals = await _walletService.fetchAdminWithdrawRequests(
          status: 'processing',
        );
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _customerChats = chats;
        _withdrawals = withdrawals;
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

  Future<void> _openEntries() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AdminEntriesView(),
      ),
    );
    if (!mounted) return;
    await _load();
    if (mounted) setState(() {});
  }

  Future<void> _openWithdrawals() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AdminWithdrawRequestsView(),
      ),
    );
    if (!mounted) return;
    await _load();
    _seen.markWithdrawalsSeen(_withdrawals);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = <_AdminChatItem>[
      _AdminChatItem(
        title: 'Entries',
        subtitle: 'Incoming sale chats by game',
        color: const Color(0xFF008069),
        leadingIcon: Icons.receipt_long_outlined,
        trailingText: _badge(_seen.unreadEntries(_customerChats)),
        onTap: _openEntries,
      ),
      _AdminChatItem(
        title: 'Referral codes',
        subtitle: 'Create and manage invite codes',
        color: const Color(0xFF4B9B8B),
        leadingIcon: Icons.card_giftcard,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AdminReferralCodesView(),
            ),
          );
        },
      ),
      _AdminChatItem(
        title: 'Withdraw requests',
        subtitle: 'Pay with screenshot, or reject',
        color: const Color(0xFFEAB308),
        leadingIcon: Icons.account_balance_wallet_outlined,
        trailingText: _badge(_seen.unreadWithdrawals(_withdrawals)),
        onTap: _openWithdrawals,
      ),
      _AdminChatItem(
        title: 'Users',
        subtitle: 'List, block, or delete customer accounts',
        color: const Color(0xFFEF4444),
        leadingIcon: Icons.people_outline,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AdminUsersView(),
            ),
          );
        },
      ),
      _AdminChatItem(
        title: 'Users hierarchy',
        subtitle: 'Browse users by referral tree',
        color: const Color(0xFF3B82F6),
        leadingIcon: Icons.account_tree_outlined,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AdminReferralTreeView(),
            ),
          );
        },
      ),
      _AdminChatItem(
        title: 'Game Settings',
        subtitle: 'Dear 1, Kerala 3, Dear 6, Dear 8',
        color: const Color(0xFFF89A2C),
        leadingIcon: Icons.sports_esports_outlined,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AdminGameChatOptionsView(),
            ),
          );
        },
      ),
      _AdminChatItem(
        title: 'Account Summary',
        subtitle: 'Total sales, winnings, and balance',
        color: const Color(0xFF437D35),
        leadingIcon: Icons.summarize_outlined,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AdminAccountSummaryView(),
            ),
          );
        },
      ),
    ];

    return WinStatusBar(
      child: Scaffold(
      backgroundColor: const Color(0xFF0B141A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  const Text(
                    'Admin Chats',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    color: const Color(0xFF111B21),
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      if (value == 'logout') {
                        SessionService.clear();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute<void>(
                            builder: (_) => const PhoneLoginView(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: Text(
                          'Log out',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  color: Color(0xFF1F2C34),
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    onTap: item.onTap,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: item.color,
                      child: Icon(
                        item.leadingIcon ?? Icons.chat_bubble,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8696A0),
                        fontSize: 12,
                      ),
                    ),
                    trailing: item.trailingText == null
                        ? const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF8696A0),
                          )
                        : CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFF25D366),
                            child: Text(
                              item.trailingText!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                  );
                },
              ),
            ),
            if (_error != null)
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
      ),
    );
  }
}

class _AdminChatItem {
  const _AdminChatItem({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.trailingText,
    this.leadingIcon,
  });

  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final String? trailingText;
  final IconData? leadingIcon;
}
