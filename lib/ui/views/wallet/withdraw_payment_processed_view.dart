import 'package:flutter/material.dart';

import '../../../services/wallet_service.dart';
import '../../theme/win_theme.dart';

class WithdrawPaymentProcessedView extends StatelessWidget {
  const WithdrawPaymentProcessedView({super.key, required this.item});

  final WithdrawRequestItem item;

  String get _when {
    final d = item.completedAt ?? item.reviewedAt ?? item.createdAt;
    if (d == null) return '';
    return WinTheme.monthDay(d.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07090C),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Payment processed',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF16351F),
                shape: BoxShape.circle,
                border: Border.all(color: WinTheme.green, width: 2),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: WinTheme.green,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Payment processed',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${WinTheme.rupee(item.amount)} sent to your account',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_when.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _when,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
          const SizedBox(height: 22),
          if (item.receiptUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Image.network(
                  item.receiptUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFF12161C),
                    alignment: Alignment.center,
                    child: const Text(
                      'Screenshot unavailable',
                      style: TextStyle(color: Color(0xFF9CA3AF)),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            decoration: BoxDecoration(
              color: const Color(0xFF12161C),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF2A323C)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paid to',
                  style: TextStyle(
                    color: Color(0xFF8B95A1),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 12),
                _DetailRow(label: 'Account', value: item.accountNumber),
                _DetailRow(label: 'IFSC', value: item.ifsc),
                _DetailRow(label: 'UPI', value: item.upiId),
                _DetailRow(
                  label: 'Amount',
                  value: '₹${WinTheme.rupee(item.amount)}',
                ),
                _DetailRow(label: 'Status', value: 'Processed'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6F7A86),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '—' : value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
