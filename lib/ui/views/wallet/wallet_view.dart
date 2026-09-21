import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../../../services/sales_service.dart';
import '../../../services/session_service.dart';
import '../../../services/wallet_balance_store.dart';
import '../../../services/wallet_service.dart';
import '../../theme/win_theme.dart';
import '../../widgets/phone_verify_sheet.dart';
import 'add_money_view.dart';
import 'withdraw_payment_processed_view.dart';
import 'withdraw_request_view.dart';

class WalletView extends StatefulWidget {
  const WalletView({
    super.key,
    this.active = true,
    this.embedded = false,
  });

  /// When this tab is shown, reload balances (IndexedStack keeps this alive).
  final bool active;
  final bool embedded;

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  static const _bgAsset = 'assets/wallet_page_bg.jpeg';

  final _service = const WalletService();
  final _salesService = const SalesService();
  bool _loading = true;
  String? _error;
  WalletSummary? _summary;
  List<WalletTransactionItem> _transactions = [];
  List<WithdrawRequestItem> _withdrawals = [];
  List<WalletTopupMessage> _topups = [];
  PayoutDetails _payoutDetails = const PayoutDetails();

  @override
  void initState() {
    super.initState();
    WalletBalanceStore.instance.addListener(_onWalletStore);
    final cached = WalletBalanceStore.instance.summary;
    if (cached != null) {
      _summary = cached;
      _loading = false;
    }
    _load(spinner: _summary == null);
  }

  @override
  void dispose() {
    WalletBalanceStore.instance.removeListener(_onWalletStore);
    super.dispose();
  }

  void _onWalletStore() {
    final cached = WalletBalanceStore.instance.summary;
    if (!mounted || cached == null) return;
    setState(() => _summary = cached);
  }

  @override
  void didUpdateWidget(WalletView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _load(
        spinner:
            WalletBalanceStore.instance.summary == null && _summary == null,
      );
    }
  }

  Future<void> _load({bool spinner = true}) async {
    if (!mounted) return;
    setState(() {
      if (spinner) _loading = true;
      _error = null;
    });
    try {
      await WalletBalanceStore.instance.refresh();
      final summary = WalletBalanceStore.instance.summary;
      if (summary == null) {
        throw Exception("Can't connect. Please try again.");
      }
      final txs = summary.isAdminWallet
          ? <WalletTransactionItem>[]
          : await _service.fetchTransactions();
      var withdrawals = <WithdrawRequestItem>[];
      var payout = summary.payoutDetails;
      var topups = <WalletTopupMessage>[];
      if (!summary.isAdminWallet) {
        final withdrawData = await _service.fetchWithdrawRequests();
        withdrawals = withdrawData.requests;
        if (withdrawData.payoutDetails.hasSavedDetails) {
          payout = withdrawData.payoutDetails;
        }
        try {
          topups = await _salesService.getMyWalletTopups();
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _summary = WalletBalanceStore.instance.summary ?? summary;
        _transactions = txs;
        _withdrawals = withdrawals;
        _topups = topups;
        _payoutDetails = payout;
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

  Future<void> _addMoney() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddMoneyView(),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _withdraw() async {
    if (!SessionService.phoneVerified) {
      try {
        final profile = await const AuthService().fetchProfile();
        if (profile?.phoneVerified == true) {
          SessionService.markPhoneVerified();
        }
      } catch (_) {}
    }
    if (!SessionService.phoneVerified) {
      if (!mounted) return;
      final phone =
          SessionService.tenDigitPhone(SessionService.displayPhoneNumber) ??
          SessionService.lastPhoneNumber ??
          '';
      final verified = await showPhoneVerifyDialog(
        context,
        countryCode: '91',
        phoneNumber: phone,
      );
      if (verified != true) return;
    }
    if (!mounted) return;
    final summary = WalletBalanceStore.instance.summary ?? _summary;
    final max = summary?.withdrawable ?? 0;
    if (max <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nothing to withdraw. You can take winning balance and withdrawable referral balance. Deposit and non withdrawable referral cannot be withdrawn.',
          ),
        ),
      );
      return;
    }
    final sent = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => WithdrawRequestView(
          maxWithdrawable: max,
          withdrawableWinnings: summary?.withdrawableWinnings ?? 0,
          withdrawableReferral: summary?.withdrawableReferral ?? 0,
          savedDetails: _payoutDetails,
        ),
      ),
    );
    if (sent == true && mounted) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Withdraw request sent.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = WalletBalanceStore.instance.summary ?? _summary;
    final admin = summary?.isAdminWallet == true;

    return WinStatusBar(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (!widget.embedded) ...[
              const ColoredBox(color: WinTheme.bg),
              const DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(_bgAsset),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),
            ],
            SafeArea(
              top: !widget.embedded,
              bottom: !widget.embedded,
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: WinTheme.green),
                    )
                  : RefreshIndicator(
                      color: WinTheme.green,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        children: [
                          _WalletTitle(
                            showBack: !widget.embedded,
                            onBack: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(height: 12),
                          _GlassCard(
                            padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                            tint: const Color(0x3322C55E),
                            borderColor: const Color(0x554ADE80),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'TOTAL AMOUNT',
                                        style: TextStyle(
                                          color: Color(0xFFD1D5DB),
                                          fontSize: 12,
                                          letterSpacing: 0.8,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    _WalletArt(),
                                  ],
                                ),
                                Text(
                                  admin
                                      ? '—'
                                      : '₹${WinTheme.rupee(summary?.total ?? 0)}',
                                  style: const TextStyle(
                                    color: WinTheme.green,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _BalanceRow(
                                  color: WinTheme.yellow,
                                  label: 'Deposit balance',
                                  value: admin
                                      ? '—'
                                      : '₹${WinTheme.rupee(summary?.deposit ?? 0)}',
                                ),
                                const SizedBox(height: 10),
                                _BalanceRow(
                                  color: WinTheme.green,
                                  label: 'Winning balance',
                                  value: admin
                                      ? '—'
                                      : '₹${WinTheme.rupee(summary?.winningsBalance ?? 0)}',
                                  valueColor: WinTheme.green,
                                ),
                                const SizedBox(height: 10),
                                _BalanceRow(
                                  color: Colors.white,
                                  label: 'Withdrawable referral balance',
                                  value: admin
                                      ? '—'
                                      : '₹${WinTheme.rupee(summary?.withdrawableReferral ?? 0)}',
                                  valueColor: Colors.white,
                                ),
                                const SizedBox(height: 10),
                                _BalanceRow(
                                  color: WinTheme.blue,
                                  label: 'Non withdrawable referral balance',
                                  value: admin
                                      ? '—'
                                      : '₹${WinTheme.rupee(summary?.nonWithdrawableReferral ?? 0)}',
                                ),
                                if (!admin &&
                                    (summary?.lockedBalance ?? 0) > 0) ...[
                                  const SizedBox(height: 10),
                                  _BalanceRow(
                                    color: Colors.orangeAccent,
                                    label: 'Processing withdraw',
                                    value:
                                        '₹${WinTheme.rupee(summary!.lockedBalance)}',
                                    valueColor: Colors.orangeAccent,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const _InfoBanner(
                            text:
                                'Play uses withdrawable referral first, then winning balance, then non withdrawable referral, then deposit. You can withdraw winning balance and withdrawable referral balance. Deposit and non withdrawable referral cannot be withdrawn.',
                          ),
                          if (!admin) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _PillButton(
                                    label: 'Add Money',
                                    icon: Icons.add,
                                    filled: true,
                                    onPressed: _addMoney,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _PillButton(
                                    label: 'Withdraw',
                                    icon: Icons.arrow_upward_rounded,
                                    filled: false,
                                    onPressed: _withdraw,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (_topups.isNotEmpty) ...[
                              const _SectionTitle(
                                icon: Icons.history_rounded,
                                title: 'Deposit history',
                              ),
                              const SizedBox(height: 12),
                              ..._topups.map(
                                (item) => _DepositTile(item: item),
                              ),
                              const SizedBox(height: 24),
                            ],
                            if (_withdrawals.isNotEmpty) ...[
                              const _SectionTitle(
                                icon: Icons.south_west_rounded,
                                title: 'Withdraw requests',
                              ),
                              const SizedBox(height: 12),
                              ..._withdrawals.map(
                                (item) => _WithdrawTile(item: item),
                              ),
                              const SizedBox(height: 24),
                            ],
                            _SectionTitle(
                              icon: Icons.receipt_long_outlined,
                              title: 'Transaction History',
                              trailing: '${_transactions.length} transactions',
                            ),
                            const SizedBox(height: 12),
                            if (_transactions.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: Text(
                                  'No transactions yet.',
                                  style: TextStyle(color: WinTheme.muted),
                                ),
                              )
                            else
                              ..._transactions.map(
                                (tx) => _TransactionTile(item: tx),
                              ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                              ),
                            ),
                          ],
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

class _WalletTitle extends StatelessWidget {
  const _WalletTitle({required this.showBack, required this.onBack});

  final bool showBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack)
          IconButton(
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wallet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            SizedBox(
              width: 46,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: WinTheme.green,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WalletArt extends StatelessWidget {
  const _WalletArt();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 8,
            child: Container(
              width: 44,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4ADE80), Color(0xFF166534)],
                ),
                border: Border.all(color: const Color(0x66FDE68A)),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: -4,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: WinTheme.gold,
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              alignment: Alignment.center,
              child: const Text(
                '₹',
                style: TextStyle(
                  color: Color(0xFF3F2A00),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.tint = const Color(0x33101820),
    this.borderColor = const Color(0x33FFFFFF),
  });

  final Widget child;
  final EdgeInsets padding;
  final Color tint;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      tint: const Color(0x3322C55E),
      borderColor: const Color(0x554ADE80),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: WinTheme.yellow,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'i',
              style: TextStyle(
                color: Color(0xFF3F2A00),
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);
    if (filled) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: const LinearGradient(
            colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x5516A34A),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            child: SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.black, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: WinTheme.green, width: 1.4),
            color: const Color(0x2216A34A),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: WinTheme.green, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: WinTheme.green,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: WinTheme.green, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Text(
            trailing!,
            style: const TextStyle(color: WinTheme.muted, fontSize: 13),
          ),
        ],
      ],
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.color,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final Color color;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.item});

  final WalletTransactionItem item;

  @override
  Widget build(BuildContext context) {
    final credit = item.direction == 'credit';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _GlassCard(
        child: Row(
          children: [
            Icon(
              credit ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: credit ? WinTheme.green : Colors.orangeAccent,
              size: 20,
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.description.isNotEmpty)
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: WinTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${credit ? '+' : '-'}₹${WinTheme.rupee(item.amount)}',
              style: TextStyle(
                color: credit ? WinTheme.green : Colors.orangeAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DepositTile extends StatelessWidget {
  const _DepositTile({required this.item});

  final WalletTopupMessage item;

  Color _statusColor() {
    if (item.isCredited) return WinTheme.green;
    if (item.isRejected) return Colors.redAccent;
    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _GlassCard(
        child: Row(
          children: [
            const Icon(Icons.add_card_outlined, color: WinTheme.green, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${WinTheme.rupee(item.amount)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'Add money',
                    style: TextStyle(color: WinTheme.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              item.isCredited ? 'Successful' : item.userStatus,
              style: TextStyle(
                color: _statusColor(),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WithdrawTile extends StatelessWidget {
  const _WithdrawTile({required this.item});

  final WithdrawRequestItem item;

  void _openProcessed(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WithdrawPaymentProcessedView(item: item),
      ),
    );
  }

  void _openImage(BuildContext context, String url) {
    Navigator.of(context).push(
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
                url,
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
  }

  @override
  Widget build(BuildContext context) {
    final isProcessed =
        item.status == 'completed' && item.receiptUrl.isNotEmpty;
    final proofUrl =
        item.status == 'rejected' ? item.rejectImageUrl : item.receiptUrl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.south_west_rounded,
                  color: WinTheme.green,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${WinTheme.rupee(item.amount)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        item.upiId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: WinTheme.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  item.displayStatus,
                  style: TextStyle(
                    color: item.statusColor(),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (item.status == 'rejected' && item.rejectReason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.rejectReason,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
            if (isProcessed) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _openProcessed(context),
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.receiptUrl,
                        height: 56,
                        width: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 56,
                          width: 56,
                          color: const Color(0xFF1F2937),
                          child: const Icon(
                            Icons.image_outlined,
                            color: WinTheme.muted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Payment processed · Tap to view screenshot',
                        style: TextStyle(
                          color: WinTheme.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: WinTheme.muted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ] else if (proofUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _openImage(context, proofUrl),
                borderRadius: BorderRadius.circular(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    proofUrl,
                    height: 88,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
