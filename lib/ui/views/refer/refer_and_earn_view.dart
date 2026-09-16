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
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Refer & Earn Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                decoration: BoxDecoration(
                  color: _headerBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/win_app_logo.png',
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'നിങ്ങളുടെ സ്വന്തം Agent',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'വേണ്ടത് ഇത്ര മാത്രം — നിങ്ങളുടെ മൂന്നക്ക നമ്പർ ലോട്ടറി എഴുത്തുകാരായ സുഹൃത്തുക്കൾക്ക് Win App share ചെയ്യുക.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 13.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'അവരെ നമ്മുടെ ആപ്പിൽ അക്കൗണ്ട് create ചെയ്യിക്കുക. അവർ ആദ്യ deposit ചെയ്യുന്നത് മുതൽ നിങ്ങൾക്ക് വരുമാനം കിട്ടി തുടങ്ങുന്നതാണ്.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 13.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const _BenefitItem(
                      icon: Icons.card_giftcard_outlined,
                      text: 'സുഹൃത്തിന് ₹50 വെൽക്കം ബോണസ്!',
                    ),
                    const SizedBox(height: 8),
                    const _BenefitItem(
                      icon: Icons.show_chart_rounded,
                      text: 'നിങ്ങൾക്ക് 5% ലൈഫ് ടൈം കമ്മീഷൻ!',
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '₹',
                          style: TextStyle(
                            color: _accent,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.sync_rounded, color: _accent, size: 21),
                        SizedBox(width: 8),
                        Text(
                          '₹',
                          style: TextStyle(
                            color: _accent,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '(അവർ പണം ചേർക്കുമ്പോൾ നിങ്ങൾക്ക് ലഭിക്കുന്നത്. ഉദാഹരണത്തിന്: ₹600 ചേർത്താൽ, നിങ്ങൾക്ക് ₹30)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'നിങ്ങളുടെ ഇൻവൈറ്റ് കോഡ്:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
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
                            vertical: 8,
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
                                    fontSize: 19,
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
            
            // WhatsApp Share Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Material(
                color: _accent,
                borderRadius: BorderRadius.circular(12),
                elevation: 2,
                child: InkWell(
                  onTap: code == '—' ? null : () => shareWinAppInvite(code),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/whatsapp_icon.png',
                          width: 24,
                          height: 24,
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
            ),
          ],
        ),
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
        Icon(icon, color: ReferAndEarnView._accent, size: 23),
        const SizedBox(height: 5),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}
