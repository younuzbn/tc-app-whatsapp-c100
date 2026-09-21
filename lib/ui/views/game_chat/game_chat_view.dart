import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';

import '../../../services/admin_service.dart';
import '../../../services/sales_service.dart';
import '../../../services/winning_service.dart';
import '../../theme/win_theme.dart';
import '../home/game_chat_data.dart';
import '../wallet/wallet_view.dart';
import 'game_chat_viewmodel.dart';

class GameChatView extends StackedView<GameChatViewModel> {
  const GameChatView({
    super.key,
    required this.game,
    this.initialTimeSetting,
  });

  final GameChatData game;
  final TimeAndCountSetting? initialTimeSetting;

  @override
  Widget builder(
    BuildContext context,
    GameChatViewModel viewModel,
    Widget? child,
  ) {
    final combinedMessages = <_ChatMessageItem>[
      ...viewModel.sales.map(
        (sale) => _ChatMessageItem(date: sale.createdDate, sale: sale),
      ),
      ...viewModel.resultMessages.map(
        (result) => _ChatMessageItem(date: result.resultDate, result: result),
      ),
      ...viewModel.winningMessages.map(
        (win) => _ChatMessageItem(
          date: win.createdAt ?? win.resultDate,
          winning: win,
        ),
      ),
    ]..sort(
      (a, b) => (b.date ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
        a.date ?? DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );

    return WinStatusBar(
      style: WinTheme.greenStatusBar,
      child: Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      resizeToAvoidBottomInset: false,
      body: Column(
          children: [
            ColoredBox(
              color: const Color(0xFF008069),
              child: SafeArea(
                bottom: false,
                child: _ChatHeader(
                  game: game,
                  subtitle: viewModel.headerCloseLabel,
                  walletBalanceLabel: viewModel.walletBalanceLabel,
                ),
              ),
            ),
            if (viewModel.showChatBanners)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ColoredBox(
                    color: Colors.white,
                    child: SizedBox(width: double.infinity, height: 1),
                  ),
                  if (viewModel.showStatusBanner)
                    _StatusBanner(
                      kind: viewModel.statusBannerKind,
                      text: viewModel.statusBannerText,
                    ),
                  _SystemBanner(
                    text: viewModel.announcementWelcomeText,
                    secondText: viewModel.showSecondSaleBanner
                        ? viewModel.announcementSecondBannerText
                        : null,
                  ),
                ],
              ),
            Expanded(
              child: SafeArea(
                top: false,
                bottom: false,
                child: Column(
                children: [
                  Expanded(
                    child: viewModel.loadingMessages
                        ? const _ChatLoadingIndicator()
                        : combinedMessages.isEmpty
                        ? const Center(
                            child: Text(
                              'No messages yet.',
                              style: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 12,
                              ),
                            ),
                          )
                        : ListView.builder(
                            reverse: true,
                            controller: viewModel.chatScrollController,
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                                  itemCount: combinedMessages.length +
                                      ((viewModel.hasOlderSales ||
                                              viewModel.loadingOlderSales)
                                          ? 1
                                          : 0),
                                  itemBuilder: (context, index) {
                                    if (index >= combinedMessages.length) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        child: Center(
                                          child: viewModel.loadingOlderSales
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const SizedBox(height: 8),
                                        ),
                                      );
                                    }
                                    final message = combinedMessages[index];
                                    final older = index + 1 < combinedMessages.length
                                        ? combinedMessages[index + 1]
                                        : null;
                                    final showDateChip = older == null ||
                                        !WinTheme.sameDay(message.date, older.date);
                                    final dateChip = showDateChip
                                        ? _ChatDateChip(label: WinTheme.dayChip(message.date))
                                        : null;
                                    if (message.sale != null) {
                                      final sale = message.sale!;
                                      final confirmed = viewModel.isSaleConfirmed(sale);
                                      return Column(
                                        key: ValueKey('sale-${sale.id}'),
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (dateChip != null) dateChip,
                                          _SaleBubble(
                                            sale: sale,
                                            showActions:
                                                viewModel.canEditOrDeleteSale(sale),
                                            isConfirmed: confirmed,
                                            onEdit: () => _showEditSaleDialog(
                                              context,
                                              viewModel,
                                              sale,
                                            ),
                                            onDelete: () => _confirmDeleteSale(
                                              context,
                                              viewModel,
                                              sale,
                                            ),
                                          ),
                                          if (confirmed) const _ThumbsUpReplyBubble(),
                                        ],
                                      );
                                    }
                                    if (message.winning != null) {
                                      return Column(
                                        key: ValueKey('win-${message.winning!.id}'),
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (dateChip != null) dateChip,
                                          _WinningBubble(report: message.winning!),
                                        ],
                                      );
                                    }
                                    return Column(
                                      key: ValueKey('result-${message.result!.id}'),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (dateChip != null) dateChip,
                                        _ResultBubble(message: message.result!),
                                      ],
                                    );
                                  },
                                ),
                  ),
                  viewModel.isGameClosed
                      ? SafeArea(
                          top: false,
                          child: _ClosedGamePanel(
                            opensAtLabel: viewModel.opensAtLabel,
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ComposerPanel(viewModel: viewModel),
                            if (viewModel.isKeyboardVisible)
                              _SaleNumericKeyboard(viewModel: viewModel)
                            else
                              SizedBox(
                                height: MediaQuery.paddingOf(context).bottom,
                              ),
                          ],
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

  @override
  GameChatViewModel viewModelBuilder(BuildContext context) =>
      GameChatViewModel(
        game: game,
        initialTimeSetting: initialTimeSetting,
      );

  @override
  void onViewModelReady(GameChatViewModel viewModel) {
    viewModel.initialise();
  }

  Future<void> _showEditSaleDialog(
    BuildContext context,
    GameChatViewModel viewModel,
    SalesRecord sale,
  ) async {
    final digits = viewModel.digitLengthForLsk(sale.lsk);
    final numberController = TextEditingController(text: sale.number);
    final countController = TextEditingController(text: '${sale.count}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  sale.lsk.toUpperCase() == 'DEAR'
                      ? 'Super'
                      : sale.lsk.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF008069),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: numberController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(digits),
                ],
                decoration: InputDecoration(
                  labelText: '$digits-digit number',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: countController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: const InputDecoration(
                  labelText: 'Count',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Wallet will be adjusted if the amount changes.',
                style: TextStyle(fontSize: 11, color: Color(0xFF667085)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    final number = numberController.text.trim();
    final count = int.tryParse(countController.text.trim()) ?? 0;
    numberController.dispose();
    countController.dispose();

    if (ok != true || !context.mounted) return;
    final success = await viewModel.updateSaleRecord(
      sale: sale,
      number: number,
      count: count,
    );
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry updated')),
      );
    }
  }

  Future<void> _confirmDeleteSale(
    BuildContext context,
    GameChatViewModel viewModel,
    SalesRecord sale,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text(
          'Remove ${sale.number}-${sale.count}? The amount will be credited back to your wallet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final success = await viewModel.deleteSaleRecord(sale);
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry deleted · wallet refunded')),
      );
    }
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.kind,
    required this.text,
  });

  final GameStatusBannerKind kind;
  final String text;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    switch (kind) {
      case GameStatusBannerKind.countdown:
        color = const Color(0xFF008069);
        icon = Icons.timer_outlined;
      case GameStatusBannerKind.gameClosed:
        color = const Color(0xFF667085);
        icon = Icons.lock_clock_outlined;
      case GameStatusBannerKind.resultPublished:
        color = const Color(0xFF0B8F78);
        icon = Icons.fact_check_outlined;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.game,
    required this.subtitle,
    required this.walletBalanceLabel,
  });

  final GameChatData game;
  final String subtitle;
  final String walletBalanceLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF008069),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: game.avatarColor.withValues(alpha: 0.35),
            child: Text(
              game.avatarText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFD8EFEA),
                    fontSize: 12,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const WalletView(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      walletBalanceLabel,
                      style: const TextStyle(
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
        ],
      ),
    );
  }
}

class _ClosedGamePanel extends StatelessWidget {
  const _ClosedGamePanel({required this.opensAtLabel});

  final String opensAtLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F2F6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_clock_outlined,
            size: 28,
            color: Color(0xFF667085),
          ),
          const SizedBox(height: 8),
          const Text(
            'Game is closed',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D2939),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            opensAtLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF008069),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerPanel extends StatelessWidget {
  const _ComposerPanel({required this.viewModel});

  final GameChatViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF1F2F6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (viewModel.errorMessage != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          Row(
            children: [
              for (final option in viewModel.currentOptions) ...[
                Expanded(
                  child: _OptionChip(
                    label: option,
                    selected: viewModel.selectedOption == option,
                    onTap: () => viewModel.selectOption(option),
                  ),
                ),
                if (option != viewModel.currentOptions.last)
                  const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: _ComposerDigitField(
                  controller: viewModel.numberController,
                  focusNode: viewModel.numberFocusNode,
                  hintText: 'Number',
                  active: viewModel.isKeyboardVisible &&
                      viewModel.activeField == 'number',
                  maxLength: viewModel.digitLength,
                  onTap: () => viewModel.setActiveField('number'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 4,
                child: _ComposerDigitField(
                  controller: viewModel.countController,
                  focusNode: viewModel.countFocusNode,
                  hintText: 'Count',
                  active: viewModel.isKeyboardVisible &&
                      viewModel.activeField == 'count',
                  maxLength: 3,
                  onTap: () => viewModel.setActiveField('count'),
                ),
              ),
              const SizedBox(width: 6),
              for (final mode in viewModel.numberModes) ...[
                _ModeChip(
                  label: mode,
                  selected: viewModel.selectedNumberMode == mode,
                  onTap: () => viewModel.selectGameType(mode),
                ),
                if (mode != viewModel.numberModes.last) const SizedBox(width: 4),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ComposerDigitField extends StatelessWidget {
  const _ComposerDigitField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.active,
    required this.maxLength,
    required this.onTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool active;
  final int maxLength;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: active ? const Color(0xFF008069) : Colors.transparent,
        width: 2,
      ),
    );
    return TextField(
      controller: controller,
      focusNode: focusNode,
      readOnly: true,
      showCursor: true,
      enableInteractiveSelection: false,
      keyboardType: TextInputType.none,
      onTap: onTap,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLength),
      ],
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
      ),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF111827),
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _selectedYellow = Color(0xFFC9A227);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: selected ? _selectedYellow : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: _selectedYellow),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : _selectedYellow,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF6B7280),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

const double _kSaleKeyHeight = 38;
const double _kSaleKeyRadius = 8;
const Color _kSaleKeyboardColor = Color(0xFF008069);
const Color _kSaleKeyBorder = Color(0xB3FFFFFF);

class _SaleNumericKeyboard extends StatelessWidget {
  const _SaleNumericKeyboard({required this.viewModel});

  final GameChatViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _kSaleKeyboardColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 2, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _numKey('1'),
                  _numKey('2'),
                  _numKey('3'),
                  _actionKey(
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    onTap: viewModel.onKeyboardBackspace,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _numKey('4'),
                  _numKey('5'),
                  _numKey('6'),
                  _actionKey(
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    onTap: viewModel.onKeyboardClear,
                    borderless: true,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _numKey('7'),
                  _numKey('8'),
                  _numKey('9'),
                  const Expanded(
                    flex: 4,
                    child: SizedBox(height: _kSaleKeyHeight),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _actionKey(
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                    onTap: viewModel.hideSaleKeyboard,
                    borderless: true,
                    flex: 2,
                  ),
                  _numKey('0'),
                  const Expanded(
                    flex: 2,
                    child: SizedBox(height: _kSaleKeyHeight),
                  ),
                  _actionKey(
                    child: viewModel.isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF008069),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₹${viewModel.amount}',
                                    style: const TextStyle(
                                      color: Color(0xFF008069),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.send_rounded,
                                    color: Color(0xFF008069),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                    onTap: viewModel.isBusy ? () {} : viewModel.submitSale,
                    color: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numKey(String label) {
    return Expanded(
      flex: 2,
      child: _PressableKeyboardKey(
        onTap: () => viewModel.onKeyboardDigit(label),
        child: Container(
          height: _kSaleKeyHeight,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: _kSaleKeyboardColor,
            borderRadius: BorderRadius.circular(_kSaleKeyRadius),
            border: Border.all(color: _kSaleKeyBorder, width: 0.5),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionKey({
    required Widget child,
    required VoidCallback onTap,
    Color? color,
    bool borderless = false,
    int flex = 4,
  }) {
    final bg = color ?? _kSaleKeyboardColor;
    return Expanded(
      flex: flex,
      child: _PressableKeyboardKey(
        onTap: onTap,
        child: Container(
          height: _kSaleKeyHeight,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: borderless
                ? null
                : BorderRadius.circular(_kSaleKeyRadius),
            border: borderless
                ? null
                : Border.all(color: _kSaleKeyBorder, width: 0.5),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class _PressableKeyboardKey extends StatefulWidget {
  const _PressableKeyboardKey({
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_PressableKeyboardKey> createState() => _PressableKeyboardKeyState();
}

class _PressableKeyboardKeyState extends State<_PressableKeyboardKey> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          _pressed ? const Color(0x66000000) : Colors.transparent,
          BlendMode.srcATop,
        ),
        child: widget.child,
      ),
    );
  }
}

class _ChatLoadingIndicator extends StatelessWidget {
  const _ChatLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF10B981),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Loading chats...',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemBanner extends StatelessWidget {
  const _SystemBanner({required this.text, this.secondText});

  final String text;
  final String? secondText;

  static const _style = TextStyle(
    color: Color(0xFF7C6227),
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: const Color(0xFFFDF0C1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: _style,
          ),
          if (secondText != null && secondText!.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE0C56A),
              ),
            ),
            Text(
              secondText!,
              textAlign: TextAlign.center,
              style: _style,
            ),
          ],
        ],
      ),
    );
  }
}

class _ChatDateChip extends StatelessWidget {
  const _ChatDateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SaleBubble extends StatelessWidget {
  const _SaleBubble({
    required this.sale,
    required this.showActions,
    required this.isConfirmed,
    required this.onEdit,
    required this.onDelete,
  });

  final SalesRecord sale;
  final bool showActions;
  final bool isConfirmed;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _labelFromLsk() {
    switch (sale.lsk.toUpperCase()) {
      case 'DEAR':
        return 'Super';
      case 'BOX':
        return 'Box';
      default:
        return sale.lsk.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = sale.placedAt ?? sale.createdDate;
    final timeLabel = time == null
        ? ''
        : '${time.toLocal().hour.toString().padLeft(2, '0')}:${time.toLocal().minute.toString().padLeft(2, '0')}';
    final tickColor =
        isConfirmed ? const Color(0xFF53BDEB) : const Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: showActions ? 250 : 230,
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          decoration: BoxDecoration(
            color: const Color(0xFFD9FDD3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '${_labelFromLsk()}  ${sale.number}-${sale.count}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    height: 1.05,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              if (showActions) ...[
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.delete_outline,
                      size: 15,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              if (timeLabel.isNotEmpty) ...[
                Text(
                  timeLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 3),
              ],
              Icon(Icons.done_all, size: 14, color: tickColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThumbsUpReplyBubble extends StatelessWidget {
  const _ThumbsUpReplyBubble();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 10, top: 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text('👍', style: TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }
}

class _ResultBubble extends StatelessWidget {
  const _ResultBubble({required this.message});

  final ResultChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.message,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ),
    );
  }
}

class _WinningBubble extends StatelessWidget {
  const _WinningBubble({required this.report});

  final WinningReport report;

  @override
  Widget build(BuildContext context) {
    final time = (report.createdAt ?? report.resultDate)?.toLocal();
    final timeLabel = time == null
        ? ''
        : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final line =
        '${WinTheme.lskLabel(report.lsk)} - ${report.number} - ${report.count} - ₹${WinTheme.rupee(report.winAmount)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You got a winning',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0B8F78),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                line,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              if (timeLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    timeLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessageItem {
  const _ChatMessageItem({
    required this.date,
    this.sale,
    this.result,
    this.winning,
  });

  final DateTime? date;
  final SalesRecord? sale;
  final ResultChatMessage? result;
  final WinningReport? winning;
}
