import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../services/session_service.dart';
import '../auth/phone_login/phone_login_view.dart';
import '../game_chat/game_chat_view.dart';
import '../results/results_chat_view.dart';
import '../wallet/wallet_view.dart';
import 'game_chat_data.dart';
import 'home_viewmodel.dart';

class HomeView extends StackedView<HomeViewModel> {
  const HomeView({super.key, required this.displayPhoneNumber});

  final String displayPhoneNumber;

  static const Color _bg = Color(0xFF0B141A);
  static const Color _surface = Color(0xFF111B21);
  static const Color _chipInactive = Color(0xFF1F2C34);
  static const Color _green = Color(0xFF25D366);
  static const Color _muted = Color(0xFF8696A0);

  @override
  Widget builder(BuildContext context, HomeViewModel viewModel, Widget? child) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              displayPhoneNumber: viewModel.displayPhoneNumber,
              walletChipText: viewModel.walletChipText,
              walletLoading: viewModel.walletLoading,
              onWalletTap: () async {
                await Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (_) => const WalletView()),
                );
                if (context.mounted) {
                  await viewModel.refreshWallet();
                }
              },
              onLogout: () {
                SessionService.clear();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(
                    builder: (_) => const PhoneLoginView(),
                  ),
                  (route) => false,
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Home',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: _SearchBar(),
            ),
            const SizedBox(height: 12),
            _FilterRow(
              selected: viewModel.selectedCategory,
              onSelected: viewModel.selectCategory,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _ChatList(category: viewModel.selectedCategory),
            ),
            const _BottomNav(),
          ],
        ),
      ),
    );
  }

  @override
  HomeViewModel viewModelBuilder(BuildContext context) =>
      HomeViewModel(displayPhoneNumber: displayPhoneNumber);
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.displayPhoneNumber,
    required this.walletChipText,
    required this.walletLoading,
    required this.onWalletTap,
    required this.onLogout,
  });

  final String displayPhoneNumber;
  final String walletChipText;
  final bool walletLoading;
  final Future<void> Function() onWalletTap;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 10, 6),
      child: Row(
        children: [
          const Text(
            'Win App',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          _CircleIconButton(
            icon: Icons.notifications_none_rounded,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          Material(
            color: HomeView._chipInactive,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onWalletTap(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 20,
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            color: HomeView._surface,
            padding: EdgeInsets.zero,
            offset: const Offset(0, 40),
            onSelected: (value) {
              if (value == 'logout') {
                onLogout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Text(
                  displayPhoneNumber,
                  style: const TextStyle(color: HomeView._muted, fontSize: 13),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Log out', style: TextStyle(color: Colors.white)),
              ),
            ],
            child: Material(
              color: HomeView._chipInactive,
              shape: const CircleBorder(),
              child: const SizedBox(
                width: 38,
                height: 38,
                child: Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeView._chipInactive,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: HomeView._chipInactive,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: const Row(
        children: [
          Icon(Icons.search, color: HomeView._muted, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ask Meta AI or Search',
              style: TextStyle(color: HomeView._muted, fontSize: 15),
            ),
          ),
        ],
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
    const chips = <(String, HomeCategory)>[
      ('Draws', HomeCategory.draws),
      ('Results', HomeCategory.results),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final chip = chips[index];
          final isSelected = selected == chip.$2;
          return Material(
            color: isSelected
                ? const Color(0xFF0D3D2E)
                : HomeView._chipInactive,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onSelected(chip.$2),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(
                  chip.$1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: chips.length,
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  const _ChatList({required this.category});

  final HomeCategory category;

  @override
  Widget build(BuildContext context) {
    final isResults = category == HomeCategory.results;

    return ListView.separated(
      padding: const EdgeInsets.only(top: 2, bottom: 8),
      itemCount: gameChats.length,
      separatorBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(left: 78),
        child: Divider(height: 1, color: Color(0xFF141414)),
      ),
      itemBuilder: (context, index) {
        final data = gameChats[index];
        final snippet = isResults
            ? 'Tap to view published results'
            : data.snippet;
        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => isResults
                    ? ResultsChatView(game: data)
                    : GameChatView(game: data),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: data.avatarColor,
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
                                color: isResults
                                    ? HomeView._muted
                                    : (data.unread != null
                                        ? const Color(0xFFB7BDC1)
                                        : HomeView._muted),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      data.time,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: !isResults && data.unread != null
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: !isResults && data.unread != null
                            ? HomeView._green
                            : HomeView._muted,
                      ),
                    ),
                    if (!isResults && data.unread != null) ...[
                      const SizedBox(height: 5),
                      Container(
                        height: 22,
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(
                          horizontal: '${data.unread}'.length > 1 ? 6 : 0,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 22,
                          minHeight: 22,
                        ),
                        decoration: BoxDecoration(
                          color: HomeView._green,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          '${data.unread}',
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
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.only(top: 6, bottom: bottom > 0 ? bottom : 8),
      decoration: const BoxDecoration(
        color: Color(0xFF000000),
        border: Border(top: BorderSide(color: Color(0xFF1A1A1A))),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavEntry(
            icon: Icons.home_rounded,
            label: 'Home',
            selected: true,
            badge: '4',
          ),
          _NavEntry(icon: Icons.call_outlined, label: 'Calls', selected: false),
          _NavEntry(
            icon: Icons.groups_2_outlined,
            label: 'Communities',
            selected: false,
          ),
          _NavEntry(
            icon: Icons.update_outlined,
            label: 'Updates',
            selected: false,
            showDot: true,
          ),
          _NavEntry(icon: null, label: 'You', selected: false, avatar: true),
        ],
      ),
    );
  }
}

class _NavEntry extends StatelessWidget {
  const _NavEntry({
    required this.icon,
    required this.label,
    required this.selected,
    this.badge,
    this.avatar = false,
    this.showDot = false,
  });

  final IconData? icon;
  final String label;
  final bool selected;
  final String? badge;
  final bool avatar;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : HomeView._muted;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              if (avatar)
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2A3942),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Icon(Icons.person, size: 16, color: color),
                )
              else
                Icon(icon, color: color, size: 24),
              if (showDot)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: HomeView._green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              if (badge != null)
                Positioned(
                  right: -10,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: HomeView._green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
