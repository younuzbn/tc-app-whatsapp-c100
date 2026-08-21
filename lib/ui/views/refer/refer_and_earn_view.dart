import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../theme/win_theme.dart';

class ReferAndEarnView extends StatelessWidget {
  const ReferAndEarnView({
    super.key,
    required this.referralCode,
    this.embedded = false,
  });

  final String referralCode;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final code = referralCode.trim().isEmpty ? '—' : referralCode.trim();
    return Scaffold(
      backgroundColor: WinTheme.bg,
      appBar: AppBar(
        backgroundColor: WinTheme.bg,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !embedded,
        title: const Text('Refer & Earn', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: WinTheme.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: WinTheme.border),
            ),
            child: Column(
              children: [
                const Icon(Icons.card_giftcard, color: WinTheme.green, size: 42),
                const SizedBox(height: 12),
                const Text(
                  'Friends get ₹50',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your friend gets ₹50 when they join with your code. You earn 5% whenever they add money to their wallet. If they add ₹600, you get ₹30 and they keep the full ₹600.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: WinTheme.muted, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Your referral code', style: TextStyle(color: WinTheme.muted)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: WinTheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WinTheme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    code,
                    style: const TextStyle(
                      color: WinTheme.green,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: code == '—'
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: code));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Referral code copied')),
                            );
                          }
                        },
                  icon: const Icon(Icons.copy_rounded, color: WinTheme.green),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: code == '—'
                  ? null
                  : () {
                      SharePlus.instance.share(
                        ShareParams(
                          text:
                              'Join WIN APP with my referral code $code. You get ₹50 on signup!',
                        ),
                      );
                    },
              icon: const Icon(Icons.share_rounded, color: Colors.black),
              label: const Text(
                'Share with friends',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: WinTheme.green,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
