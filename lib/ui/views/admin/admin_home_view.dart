import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/admin_inbox_seen_store.dart';
import '../../../services/sales_service.dart';
import '../../../services/session_service.dart';
import '../../../services/support_service.dart';
import '../../../services/wallet_service.dart';
import '../../theme/win_theme.dart';
import '../auth/phone_login/phone_login_view.dart';
import 'admin_account_summary_view.dart';
import 'admin_entries_view.dart';
import 'admin_game_chat_options_view.dart';
import 'admin_referral_codes_view.dart';
import 'admin_referral_tree_view.dart';
import 'admin_users_view.dart';
import 'admin_complaints_view.dart';
import 'admin_withdraw_requests_view.dart';

class AdminHomeView extends StatefulWidget {
  const AdminHomeView({super.key});

  @override
  State<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends State<AdminHomeView> {
  static const _bgAsset = 'assets/admin_home_bg.jpeg';
  static const _bg = Color(0xFF03101C);
  static const _statusBar = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: _bg,
    systemNavigationBarIconBrightness: Brightness.light,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  );

  final _salesService = const SalesService();
  final _walletService = const WalletService();
  final _supportService = const SupportService();
  final _seen = AdminInboxSeenStore.instance;
  Timer? _pollTimer;
  bool _loading = true;
  String? _error;
  List<CustomerChatSummary> _customerChats = [];
  List<WithdrawRequestItem> _withdrawals = [];
  int _complaintUnread = 0;

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
      final complaintUnread = await _supportService.fetchAdminUnreadCount(
        since: _seen.complaintsSeenAt,
      );
      if (!mounted) return;
      setState(() {
        _customerChats = chats;
        _withdrawals = withdrawals;
        _complaintUnread = complaintUnread;
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

  Future<void> _openComplaints() async {
    _seen.markComplaintsSeen();
    if (mounted) setState(() => _complaintUnread = 0);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AdminComplaintsView(),
      ),
    );
    if (!mounted) return;
    _seen.markComplaintsSeen();
    await _load();
  }

  void _logout() {
    SessionService.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const PhoneLoginView(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = <_AdminChatItem>[
      _AdminChatItem(
        title: 'Entries',
        subtitle: 'Incoming sale chats by game',
        accent: const Color(0xFF0F9B8E),
        leadingIcon: Icons.receipt_long_rounded,
        trailingText: _badge(_seen.unreadEntries(_customerChats)),
        badgeColor: const Color(0xFF2DD4BF),
        onTap: _openEntries,
      ),
      _AdminChatItem(
        title: 'Referral codes',
        subtitle: 'Create and manage invite codes',
        accent: const Color(0xFF7C3AED),
        leadingIcon: Icons.card_giftcard_rounded,
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
        accent: const Color(0xFFD97706),
        leadingIcon: Icons.account_balance_wallet_rounded,
        trailingText: _badge(_seen.unreadWithdrawals(_withdrawals)),
        badgeColor: const Color(0xFFFBBF24),
        onTap: _openWithdrawals,
      ),
      _AdminChatItem(
        title: 'Complaints',
        subtitle: 'Customer support chats',
        accent: const Color(0xFF059669),
        leadingIcon: Icons.support_agent_rounded,
        trailingText: _badge(_complaintUnread),
        badgeColor: const Color(0xFF25D366),
        onTap: _openComplaints,
      ),
      _AdminChatItem(
        title: 'Users',
        subtitle: 'List, block, or delete customer accounts',
        accent: const Color(0xFFE11D48),
        leadingIcon: Icons.people_alt_rounded,
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
        accent: const Color(0xFF2563EB),
        leadingIcon: Icons.account_tree_rounded,
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
        accent: const Color(0xFFEA580C),
        leadingIcon: Icons.sports_esports_rounded,
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
        accent: const Color(0xFF16A34A),
        leadingIcon: Icons.summarize_rounded,
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
      style: _statusBar,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: _bg),
            const DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(_bgAsset),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 10, 8, 14),
                    child: _AdminHeader(),
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2EE6D6),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            itemCount: items.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              return _AdminMenuCard(item: items[index]);
                            },
                          ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 8,
              child: PopupMenuButton<String>(
                color: const Color(0xFF0F2744),
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'logout') _logout();
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
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Admin ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    TextSpan(
                      text: 'Chats',
                      style: TextStyle(
                        color: Color(0xFF2EE6D6),
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Manage your platform with ease',
                style: TextStyle(
                  color: Color(0xFF9CA8B8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 36),
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 36),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
                decoration: BoxDecoration(
                  color: const Color(0x66101C33),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0x55FDE68A)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFFFBBF24),
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Control Panel',
                          style: TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  const _AdminMenuCard({required this.item});

  final _AdminChatItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 78,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                item.accent.withValues(alpha: 0.95),
                item.accent.withValues(alpha: 0.42),
                const Color(0xCC071526),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.55, 1.0],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: item.accent.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: 44,
                top: 10,
                bottom: 10,
                child: Icon(
                  item.leadingIcon,
                  size: 54,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 10, 0),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        item.leadingIcon,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.trailingText != null) ...[
                      Container(
                        constraints: const BoxConstraints(minWidth: 22),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: item.badgeColor ?? const Color(0xFF2DD4BF),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          item.trailingText!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF052E16),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
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
    required this.accent,
    required this.onTap,
    this.trailingText,
    this.badgeColor,
    this.leadingIcon,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final String? trailingText;
  final Color? badgeColor;
  final IconData? leadingIcon;
}
