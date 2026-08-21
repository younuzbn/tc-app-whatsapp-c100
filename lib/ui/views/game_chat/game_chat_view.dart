import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';

import '../../../services/sales_service.dart';
import '../../theme/win_theme.dart';
import '../home/game_chat_data.dart';
import 'game_chat_viewmodel.dart';

class GameChatView extends StackedView<GameChatViewModel> {
  const GameChatView({super.key, required this.game});

  final GameChatData game;

  @override
  Widget builder(
    BuildContext context,
    GameChatViewModel viewModel,
    Widget? child,
  ) {
    viewModel.initialise();
    final combinedMessages = <_ChatMessageItem>[
      ...viewModel.sales.map(
        (sale) => _ChatMessageItem(date: sale.createdDate, sale: sale),
      ),
      ...viewModel.resultMessages.map(
        (result) => _ChatMessageItem(date: result.resultDate, result: result),
      ),
      ...viewModel.walletTopups.map(
        (topup) => _ChatMessageItem(date: topup.createdAt, topup: topup),
      ),
    ]..sort(
      (a, b) => (b.date ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
        a.date ?? DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(
              game: game,
              subtitle: viewModel.headerCloseLabel,
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                          child: Column(
                            children: [
                              if (viewModel.showStatusBanner) ...[
                                _StatusBanner(
                                  kind: viewModel.statusBannerKind,
                                  text: viewModel.statusBannerText,
                                ),
                                const SizedBox(height: 8),
                              ],
                              _SystemBanner(
                                text: viewModel.announcementWelcomeText,
                              ),
                              if (viewModel.showSecondSaleBanner) ...[
                                const SizedBox(height: 8),
                                _SystemBanner(
                                  text: viewModel.announcementSecondBannerText,
                                ),
                              ],
                              if (viewModel.errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
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
                          ),
                        ),
                        Expanded(
                          child: combinedMessages.isEmpty && !viewModel.isBusy
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
                                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 170),
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
                                    if (message.topup != null) {
                                      return Column(
                                        key: ValueKey('topup-${message.topup!.id}'),
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (dateChip != null) dateChip,
                                          _DepositRequestBubble(topup: message.topup!),
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
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: viewModel.isGameClosed
                        ? _ClosedGamePanel(opensAtLabel: viewModel.opensAtLabel)
                        : _ComposerPanel(viewModel: viewModel),
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
  GameChatViewModel viewModelBuilder(BuildContext context) =>
      GameChatViewModel(game: game);

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
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
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
  });

  final GameChatData game;
  final String subtitle;

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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFFD8EFEA), fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.more_vert, color: Colors.white),
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
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (final mode in viewModel.numberModes) ...[
                Expanded(
                  child: _ModeChip(
                    label: mode,
                    selected: viewModel.selectedNumberMode == mode,
                    onTap: () => viewModel.selectGameType(mode),
                  ),
                ),
                if (mode != viewModel.numberModes.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 10),
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
                if (option != viewModel.currentOptions.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextField(
                  controller: viewModel.numberController,
                  focusNode: viewModel.numberFocusNode,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(viewModel.digitLength),
                  ],
                  decoration: InputDecoration(
                    hintText: viewModel.numberHint,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: viewModel.countController,
                  focusNode: viewModel.countFocusNode,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Count',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '₹${viewModel.amount}',
                style: const TextStyle(
                  color: Color(0xFF008069),
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Bal: ${viewModel.walletBalanceLabel}',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 16),
              ),
              const Spacer(),
              InkWell(
                onTap: viewModel.isBusy ? null : viewModel.submitSale,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: viewModel.isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF008069) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF008069)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF008069),
            fontWeight: FontWeight.w700,
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

class _SystemBanner extends StatelessWidget {
  const _SystemBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF0C1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF7C6227),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
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
    final billDate = sale.createdDate ?? sale.placedAt;
    final time = sale.placedAt ?? sale.createdDate;
    final timeLabel = time == null
        ? ''
        : '${time.toLocal().hour.toString().padLeft(2, '0')}:${time.toLocal().minute.toString().padLeft(2, '0')}';
    final dateLabel = WinTheme.monthDay(billDate);
    final stamp = [
      if (dateLabel.isNotEmpty) dateLabel,
      if (timeLabel.isNotEmpty) timeLabel,
    ].join(' · ');
    final tickColor =
        isConfirmed ? const Color(0xFF53BDEB) : const Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: showActions ? 250 : 230),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          decoration: BoxDecoration(
            color: const Color(0xFFD9FDD3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Text(
                      _labelFromLsk(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  if (showActions) ...[
                    InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${sale.number}-${sale.count}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (dateLabel.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Sale date $dateLabel',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
              const SizedBox(height: 3),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (stamp.isNotEmpty) ...[
                      Text(
                        stamp,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Icon(Icons.done_all, size: 15, color: tickColor),
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

class _DepositRequestBubble extends StatelessWidget {
  const _DepositRequestBubble({required this.topup});

  final WalletTopupMessage topup;

  Color get _statusColor {
    if (topup.isCredited) return const Color(0xFF0B8F78);
    if (topup.isRejected) return const Color(0xFFDC2626);
    return const Color(0xFFD97706);
  }

  @override
  Widget build(BuildContext context) {
    final time = topup.createdAt?.toLocal();
    final timeLabel = time == null
        ? ''
        : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final dateLabel = WinTheme.monthDay(topup.createdAt);
    final stamp = [
      if (dateLabel.isNotEmpty) dateLabel,
      if (timeLabel.isNotEmpty) timeLabel,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 250),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          decoration: BoxDecoration(
            color: const Color(0xFFD9FDD3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add money request',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '₹${topup.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                topup.userStatus,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _statusColor,
                ),
              ),
              if (topup.screenshotUrl.isNotEmpty) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                          backgroundColor: Colors.black,
                          appBar: AppBar(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                          body: Center(
                            child: InteractiveViewer(
                              child: Image.network(
                                topup.screenshotUrl,
                                errorBuilder: (_, _, _) => const Text(
                                  'Unable to load image',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      topup.screenshotUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 80,
                        color: const Color(0xFFE5E7EB),
                        alignment: Alignment.center,
                        child: const Text(
                          'Screenshot unavailable',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (stamp.isNotEmpty) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    stamp,
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
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text('👍', style: TextStyle(fontSize: 22)),
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

class _ChatMessageItem {
  const _ChatMessageItem({
    required this.date,
    this.sale,
    this.result,
    this.topup,
  });

  final DateTime? date;
  final SalesRecord? sale;
  final ResultChatMessage? result;
  final WalletTopupMessage? topup;
}
