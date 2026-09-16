import 'package:flutter/material.dart';

import '../../../services/sales_service.dart';
import '../../../services/wallet_service.dart';
import '../../theme/win_theme.dart';
import 'add_money_view.dart';
import 'withdraw_request_view.dart';

class WalletView extends StatefulWidget {
  const WalletView({super.key});

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
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
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await _service.fetchSummary();
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
        _summary = summary;
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
    final max = _summary?.withdrawable ?? 0;
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
          withdrawableWinnings: _summary?.withdrawableWinnings ?? 0,
          withdrawableReferral: _summary?.withdrawableReferral ?? 0,
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
    final summary = _summary;
    final admin = summary?.isAdminWallet == true;

    return Scaffold(
      backgroundColor: WinTheme.bg,
      appBar: AppBar(
        backgroundColor: WinTheme.bg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Wallet',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: WinTheme.green))
          : RefreshIndicator(
              color: WinTheme.green,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                    decoration: BoxDecoration(
                      color: WinTheme.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: WinTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL AMOUNT',
                          style: TextStyle(
                            color: WinTheme.muted,
                            fontSize: 12,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          admin ? '—' : '₹${WinTheme.rupee(summary?.total ?? 0)}',
                          style: const TextStyle(
                            color: WinTheme.green,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _BalanceRow(
                          color: WinTheme.yellow,
                          label: 'Deposit balance',
                          value: admin ? '—' : '₹${WinTheme.rupee(summary?.deposit ?? 0)}',
                        ),
                        const SizedBox(height: 10),
                        _BalanceRow(
                          color: WinTheme.green,
                          label: 'Winning balance',
                          value: admin ? '—' : '₹${WinTheme.rupee(summary?.winningsBalance ?? 0)}',
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
                        if (!admin && (summary?.lockedBalance ?? 0) > 0) ...[
                          const SizedBox(height: 10),
                          _BalanceRow(
                            color: Colors.orangeAccent,
                            label: 'Processing withdraw',
                            value: '₹${WinTheme.rupee(summary!.lockedBalance)}',
                            valueColor: Colors.orangeAccent,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: WinTheme.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: WinTheme.border),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: WinTheme.muted, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Play uses withdrawable referral first, then winning balance, then non withdrawable referral, then deposit. You can withdraw winning balance and withdrawable referral balance. Deposit and non withdrawable referral cannot be withdrawn.',
                            style: TextStyle(
                              color: WinTheme.muted,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!admin) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: _addMoney,
                              icon: const Icon(Icons.add, color: Colors.black),
                              label: const Text(
                                'Add Money',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: WinTheme.green,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _withdraw,
                              icon: const Icon(Icons.arrow_upward_rounded),
                              label: const Text(
                                'Withdraw',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: WinTheme.green,
                                side: const BorderSide(color: WinTheme.green),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_topups.isNotEmpty) ...[
                      const Text(
                        'Deposit requests',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._topups.map((item) => _DepositTile(item: item)),
                      const SizedBox(height: 24),
                    ],
                    if (_withdrawals.isNotEmpty) ...[
                      const Text(
                        'Withdraw requests',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._withdrawals.map((item) => _WithdrawTile(item: item)),
                      const SizedBox(height: 24),
                    ],
                    Row(
                      children: [
                        const Text(
                          'Transaction History',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_transactions.length} transactions',
                          style: const TextStyle(color: WinTheme.muted, fontSize: 13),
                        ),
                      ],
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
                      ..._transactions.map((tx) => _TransactionTile(item: tx)),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
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
          child: Text(label, style: const TextStyle(color: WinTheme.muted, fontSize: 14)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WinTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WinTheme.border),
      ),
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
                    style: const TextStyle(color: WinTheme.muted, fontSize: 12),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WinTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WinTheme.border),
      ),
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
            item.userStatus,
            style: TextStyle(
              color: _statusColor(),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawTile extends StatelessWidget {
  const _WithdrawTile({required this.item});

  final WithdrawRequestItem item;

  void _openImage(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
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
    final proofUrl = item.status == 'rejected' ? item.rejectImageUrl : item.receiptUrl;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WinTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WinTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.south_west_rounded, color: WinTheme.green, size: 20),
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
                      style: const TextStyle(color: WinTheme.muted, fontSize: 12),
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
          if (proofUrl.isNotEmpty) ...[
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
    );
  }
}
