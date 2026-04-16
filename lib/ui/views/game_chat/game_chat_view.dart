import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';

import '../../../services/sales_service.dart';
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
    ]..sort(
      (a, b) => (a.date ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
        b.date ?? DateTime.fromMillisecondsSinceEpoch(0),
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
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 170),
                      children: [
                        _SystemBanner(
                          text: viewModel.announcementWelcomeText,
                        ),
                        if (viewModel.showSecondSaleBanner) ...[
                          const SizedBox(height: 8),
                          _SystemBanner(
                            text: viewModel.announcementSecondBannerText,
                          ),
                        ],
                        const SizedBox(height: 14),
                        if (viewModel.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
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
                        if (combinedMessages.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'No messages yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                            ),
                          ),
                        ...combinedMessages.map((message) {
                          if (message.sale != null) {
                            return _SaleBubble(sale: message.sale!);
                          }
                          return _ResultBubble(message: message.result!);
                        }),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _ComposerPanel(viewModel: viewModel),
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

class _SaleBubble extends StatelessWidget {
  const _SaleBubble({required this.sale});

  final SalesRecord sale;

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
    final time = sale.createdDate;
    final timeLabel = time == null
        ? ''
        : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 180),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          decoration: BoxDecoration(
            color: const Color(0xFFD9FDD3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _labelFromLsk(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Color(0xFF0F172A),
                ),
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
              if (timeLabel.isNotEmpty) ...[
                const SizedBox(height: 3),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    timeLabel,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
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
  const _ChatMessageItem({required this.date, this.sale, this.result});

  final DateTime? date;
  final SalesRecord? sale;
  final ResultChatMessage? result;
}
