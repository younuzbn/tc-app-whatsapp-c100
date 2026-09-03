import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/referral_share.dart';
import '../../theme/win_theme.dart';
import '../price_chart/price_chart_view.dart';

class ReferAndEarnView extends StatelessWidget {
  const ReferAndEarnView({
    super.key,
    required this.referralCode,
    this.embedded = false,
  });

  final String referralCode;
  final bool embedded;

  static const Color _headerBg = Color(0xFFF7F7F7);
  static const Color _accent = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    final code = referralCode.trim().isEmpty ? '—' : referralCode.trim();

    return Scaffold(
      backgroundColor: WinTheme.bg,
      appBar: embedded
          ? null
          : AppBar(
              backgroundColor: WinTheme.bg,
              foregroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Refer & Earn',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: BoxDecoration(
                      color: _headerBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/win_app_logo.png',
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'നിങ്ങളുടെ സ്വന്തം Agent',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'വേണ്ടത് ഇത്ര മാത്രം — നിങ്ങളുടെ മൂന്നക്ക നമ്പർ ലോട്ടറി എഴുത്തുകാരായ സുഹൃത്തുക്കൾക്ക് Win App share ചെയ്യുക.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 12.5,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'അവരെ നമ്മുടെ ആപ്പിൽ അക്കൗണ്ട് create ചെയ്യിക്കുക. അവർ ആദ്യ deposit ചെയ്യുന്നത് മുതൽ നിങ്ങൾക്ക് വരുമാനം കിട്ടി തുടങ്ങുന്നതാണ്.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 12.5,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const _BenefitItem(
                          icon: Icons.card_giftcard_outlined,
                          text: 'സുഹൃത്തിന് ₹50 വെൽക്കം ബോണസ്!',
                        ),
                        const SizedBox(height: 10),
                        const _BenefitItem(
                          icon: Icons.show_chart_rounded,
                          text: 'നിങ്ങൾക്ക് 5% ലൈഫ് ടൈം കമ്മീഷൻ!',
                        ),
                        const SizedBox(height: 14),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '₹',
                              style: TextStyle(
                                color: _accent,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.sync_rounded, color: _accent, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '₹',
                              style: TextStyle(
                                color: _accent,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '(അവർ പണം ചേർക്കുമ്പോൾ നിങ്ങൾക്ക് ലഭിക്കുന്നത്. ഉദാഹരണത്തിന്: ₹600 ചേർത്താൽ, നിങ്ങൾക്ക് ₹30)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'നിങ്ങളുടെ ഇൻവൈറ്റ് കോഡ്:',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          elevation: 1,
                          child: InkWell(
                            onTap: code == '—'
                                ? null
                                : () => _copy(context, code, 'Invite code copied'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      code.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF111827),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.copy_rounded,
                                    color: Color(0xFF6B7280),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: _accent,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: InkWell(
              onTap: code == '—' ? null : () => shareWinAppInvite(code),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/whatsapp_icon.png',
                      width: 28,
                      height: 28,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'ഷെയർ ചെയ്യൂ, വിജയിക്കൂ!',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Material(
            color: WinTheme.bg,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PriceChartView(embedded: false),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.workspace_premium_outlined,
                      color: WinTheme.muted,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'View Price Chart',
                      style: TextStyle(
                        color: WinTheme.muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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

  static Future<void> _copy(
    BuildContext context,
    String text,
    String message,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: ReferAndEarnView._accent, size: 22),
        const SizedBox(height: 6),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
