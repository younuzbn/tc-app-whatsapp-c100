import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../services/session_service.dart';
import '../../theme/win_theme.dart';
import '../entries/my_entries_view.dart';
import '../game_chat/game_chat_view.dart';
import '../notifications/notifications_view.dart';
import '../price_chart/price_chart_view.dart';
import '../profile/profile_view.dart';
import '../refer/refer_and_earn_view.dart';
import '../results/results_list_view.dart';
import '../wallet/add_money_view.dart';
import '../wallet/wallet_view.dart';
import '../winning/winning_chat_view.dart';
import 'game_chat_data.dart';
import 'home_viewmodel.dart';

class HomeView extends StackedView<HomeViewModel> {
  const HomeView({super.key, required this.displayPhoneNumber});

  final String displayPhoneNumber;

  static const Color _bg = Color(0xFF0B141A);
  static const Color _green = Color(0xFF25D366);
  static const Color _muted = Color(0xFF8696A0);
  static const Color _gold = Color(0xFFEAB308);
  static const String _homeBgAsset = 'assets/home_bg.jpeg';
  static const String _walletBgAsset = 'assets/wallet_page_bg.jpeg';
  static const String _profileBgAsset = 'assets/profile_bg.jpeg';

  @override
  Widget builder(BuildContext context, HomeViewModel viewModel, Widget? child) {
    final shellBg = switch (viewModel.selectedTab) {
      HomeTab.wallet => _walletBgAsset,
      HomeTab.profile => _profileBgAsset,
      _ => _homeBgAsset,
    };
    return WinStatusBar(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: _bg),
            DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(shellBg),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _TopBar(
                    displayPhoneNumber: viewModel.displayPhoneNumber,
                    walletChipText: viewModel.walletChipText,
                    walletLoading: viewModel.walletLoading,
                    unreadNotifications: viewModel.unreadNotifications,
                    selectedTab: viewModel.selectedTab,
                    onNotificationsTap: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationsView(),
                        ),
                      );
                      if (context.mounted) {
                        await viewModel.refreshNotifications();
                      }
                    },
                    onAddMoneyTap: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const AddMoneyView(),
                        ),
                      );
                      if (context.mounted) {
                        await viewModel.refreshWallet();
                      }
                    },
                    onPriceChartTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const PriceChartView(embedded: false),
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: viewModel.selectedTab.index,
                      children: [
                        _HomeTabBody(viewModel: viewModel),
                        ReferAndEarnView(
                          embedded: true,
                          referralCode: SessionService.referralCode ?? '',
                        ),
                        WalletView(
                          embedded: true,
                          active: viewModel.selectedTab == HomeTab.wallet,
                        ),
                        const ProfileView(embedded: true),
                      ],
                    ),
                  ),
                  _BottomNav(
                    selected: viewModel.selectedTab,
                    onDigits: () => viewModel.selectTab(HomeTab.digits),
                    onRefer: () => viewModel.selectTab(HomeTab.refer),
                    onWallet: () => viewModel.selectTab(HomeTab.wallet),
                    onProfile: () => viewModel.selectTab(HomeTab.profile),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  HomeViewModel viewModelBuilder(BuildContext context) =>
      HomeViewModel(displayPhoneNumber: displayPhoneNumber);
}

class _HomeTabBody extends StatelessWidget {
  const _HomeTabBody({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _FilterRow(
          selected: viewModel.selectedCategory,
          onSelected: viewModel.selectCategory,
        ),
        if (viewModel.selectedCategory != HomeCategory.myEntries)
          const _TodayDateLabel(),
        Expanded(
          child: _ChatList(
            category: viewModel.selectedCategory,
            viewModel: viewModel,
            onReturned: viewModel.refreshHome,
          ),
        ),
      ],
    );
  }
}

class _TodayDateLabel extends StatelessWidget {
  const _TodayDateLabel();

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final label =
        '${_weekdays[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: _Glass(
        borderRadius: 16,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.displayPhoneNumber,
    required this.walletChipText,
    required this.walletLoading,
    required this.unreadNotifications,
    required this.selectedTab,
    required this.onAddMoneyTap,
    required this.onNotificationsTap,
    required this.onPriceChartTap,
  });

  final String displayPhoneNumber;
  final String walletChipText;
  final bool walletLoading;
  final int unreadNotifications;
  final HomeTab selectedTab;
  final Future<void> Function() onAddMoneyTap;
  final Future<void> Function() onNotificationsTap;
  final VoidCallback onPriceChartTap;

  @override
  Widget build(BuildContext context) {
    final isReferTab = selectedTab == HomeTab.refer;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 10, 16),
      child: Row(
        children: [
          Stack(
            children: [
              Text(
                'WIN APP',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 2.4
                    ..color = Colors.black,
                  shadows: const [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                    Shadow(
                      color: Colors.black,
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
              const Text(
                'WIN APP',
                style: TextStyle(
                  color: HomeView._green,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isReferTab) ...[
            // Prize Chart button on Refer & Earn tab
            _Glass(
              borderRadius: 20,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onPriceChartTap,
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Prize Chart',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            _Glass(
              borderRadius: 20,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onAddMoneyTap(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Add Money',
                          style: TextStyle(
                            color: Color(0xFFE8EDF0),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: HomeView._green,
                            boxShadow: [
                              BoxShadow(
                                color: HomeView._green.withValues(alpha: 0.45),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.black,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (walletLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: HomeView._green,
                            ),
                          )
                        else
                          Text(
                            walletChipText.isEmpty ? '—' : walletChipText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _NotificationButton(
              unread: unreadNotifications,
              onTap: () => onNotificationsTap(),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.unread, required this.onTap});

  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      borderRadius: 19,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Center(
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                if (unread > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: HomeView._green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.selected,
    required this.onSelected,
  });

  final HomeCategory selected;
  final ValueChanged<HomeCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    const chips = <(String, String, HomeCategory)>[
      ('🎟️', 'DRAWS', HomeCategory.draws),
      ('🏆', 'RESULTS', HomeCategory.results),
      ('💰', 'WINNINGS', HomeCategory.winning),
      ('📋', 'MY ENTRIES', HomeCategory.myEntries),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: HomeView._gold.withValues(alpha: 0.22),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            for (final chip in chips)
              Expanded(
                child: InkWell(
                  onTap: () => onSelected(chip.$3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              chip.$1,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, height: 1.1),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              chip.$2,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: selected == chip.$3
                                    ? Colors.white
                                    : HomeView._muted,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 2,
                        color: selected == chip.$3
                            ? HomeView._green
                            : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  const _ChatList({
    required this.category,
    required this.viewModel,
    required this.onReturned,
  });

  final HomeCategory category;
  final HomeViewModel viewModel;
  final Future<void> Function() onReturned;

  @override
  Widget build(BuildContext context) {
    if (category == HomeCategory.myEntries) {
      return const MyEntriesView(embedded: true);
    }
    if (category == HomeCategory.winning) {
      return const WinningChatView(embedded: true);
    }
    if (category == HomeCategory.results) {
      return const ResultsListView(embedded: true);
    }

    final isDraws = category == HomeCategory.draws;

    String snippetFor(GameChatData data) {
      switch (category) {
        case HomeCategory.draws:
          return viewModel.drawSnippet(data);
        case HomeCategory.results:
          return 'Tap to view published results';
        case HomeCategory.winning:
          return 'Tap to view your winning report';
        case HomeCategory.myEntries:
          return 'Tap to view your saved entries';
      }
    }

    Widget pageFor(GameChatData data) {
      switch (category) {
        case HomeCategory.draws:
          return GameChatView(
            game: data,
            initialTimeSetting: viewModel.timeSettingFor(data.timeSlot),
          );
        case HomeCategory.results:
          return const ResultsListView();
        case HomeCategory.winning:
          return WinningChatView(game: data);
        case HomeCategory.myEntries:
          return MyEntriesView(game: data);
      }
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 2, bottom: 16),
      itemCount: gameChats.length + (isDraws ? 1 : 0),
      separatorBuilder: (context, index) {
        if (isDraws && index >= gameChats.length - 1) {
          return const SizedBox.shrink();
        }
        return const SizedBox(height: 8);
      },
      itemBuilder: (context, index) {
        if (isDraws && index == gameChats.length) {
          return const _DrawsHintBox();
        }
        final data = gameChats[index];
        final snippet = snippetFor(data);
        final countingDown = isDraws && viewModel.isDrawCountingDown(data);
        final closed = isDraws && viewModel.isDrawClosed(data);
        final resultOut = isDraws && viewModel.isResultPublished(data);
        final unreadCount = isDraws ? viewModel.drawUnreadCount(data) : 0;
        final hasUnread = unreadCount > 0;
        final timeLabel = isDraws ? viewModel.drawTimeLabel(data) : data.time;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _Glass(
            borderRadius: 18,
            color: const Color(0x18FFFFFF),
            borderColor: Color.lerp(
              data.avatarColor.withValues(alpha: 0.55),
              const Color(0x55FFFFFF),
              0.35,
            )!,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                data.avatarColor.withValues(alpha: 0.32),
                const Color(0x14FFFFFF),
                data.avatarColor.withValues(alpha: 0.22),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => pageFor(data),
                    ),
                  );
                  if (isDraws) {
                    await viewModel.markDrawAlertsSeen(data.timeSlot);
                  }
                  await onReturned();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(data.avatarColor, Colors.white, 0.28)!,
                              data.avatarColor,
                              Color.lerp(data.avatarColor, Colors.black, 0.18)!,
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: data.avatarColor.withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          data.avatarText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    data.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    snippet,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: resultOut
                                          ? HomeView._green
                                          : closed
                                          ? HomeView._muted
                                          : hasUnread
                                          ? const Color(0xFFB7BDC1)
                                          : const Color(0xFFC5CDD3),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 108,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _Glass(
                              borderRadius: 14,
                              color: const Color(0x22000000),
                              borderColor: const Color(0x33FFFFFF),
                              blur: 8,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    timeLabel,
                                    maxLines: 1,
                                    softWrap: false,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: countingDown
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: countingDown
                                          ? HomeView._green
                                          : const Color(0xFFE8EDF0),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (hasUnread) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: HomeView._green,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: HomeView._green.withValues(
                                        alpha: 0.45,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DrawsHintBox extends StatelessWidget {
  const _DrawsHintBox();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: _Glass(
        borderRadius: 12,
        color: const Color(0x2216A34A),
        borderColor: const Color(0x664ADE80),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0x3322C55E),
            Color(0x1416A34A),
            Color(0x3322C55E),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.touch_app_rounded,
                color: HomeView._green,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tap a draw to open the chat and place entries',
                  style: TextStyle(
                    color: Color(0xFFE8EDF0),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.selected,
    required this.onDigits,
    required this.onRefer,
    required this.onWallet,
    required this.onProfile,
  });

  final HomeTab selected;
  final VoidCallback onDigits;
  final VoidCallback onRefer;
  final VoidCallback onWallet;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ColoredBox(
      color: HomeView._bg,
      child: Padding(
        padding: EdgeInsets.only(top: 6, bottom: bottom > 0 ? bottom : 8),
        child: Row(
          children: [
            _NavEntry(
              icon: Icons.grid_view_rounded,
              label: '3 DIGITS',
              selected: selected == HomeTab.digits,
              onTap: onDigits,
            ),
            _NavEntry(
              icon: Icons.card_giftcard_outlined,
              label: 'Refer & Earn',
              selected: selected == HomeTab.refer,
              onTap: onRefer,
            ),
            _NavEntry(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Wallet',
              selected: selected == HomeTab.wallet,
              onTap: onWallet,
            ),
            _NavEntry(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              selected: selected == HomeTab.profile,
              onTap: onProfile,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavEntry extends StatelessWidget {
  const _NavEntry({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? HomeView._green : HomeView._muted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
              shadows: selected
                  ? const [Shadow(color: Color(0x8822C55E), blurRadius: 12)]
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({
    required this.child,
    this.borderRadius = 18,
    this.color = const Color(0x22FFFFFF),
    this.borderColor = const Color(0x44FDE68A),
    this.blur = 16,
    this.gradient,
  });

  final Widget child;
  final double borderRadius;
  final Color color;
  final Color borderColor;
  final double blur;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: gradient == null ? color : null,
            gradient: gradient,
            border: Border.all(color: borderColor),
          ),
          child: child,
        ),
      ),
    );
  }
}
