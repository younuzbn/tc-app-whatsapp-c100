import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/referral_share.dart';
import '../../theme/win_theme.dart';

class ReferAndEarnView extends StatelessWidget {
  const ReferAndEarnView({
    super.key,
    required this.referralCode,
    this.embedded = false,
  });

  final String referralCode;
  final bool embedded;

  static const Color _headerBg = Color(0xFFFFFFFF);
  static const Color _accent = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    final code = referralCode.trim().isEmpty ? '—' : referralCode.trim();

    return Scaffold(
      backgroundColor: WinTheme.bg,
      resizeToAvoidBottomInset: false,
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = (constraints.maxHeight / 640).clamp(0.68, 1.0);
          final side = 16.0 * scale;
          final cardPad = 12.0 * scale;
          final gap = 8.0 * scale;

          return Padding(
            padding: EdgeInsets.fromLTRB(side, 6 * scale, side, 6 * scale),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _headerBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: (constraints.maxWidth - side * 2)
                            .clamp(200.0, 480.0),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            cardPad,
                            8 * scale,
                            cardPad,
                            10 * scale,
                          ),
                          child: _ReferCardBody(
                            code: code,
                            scale: scale,
                            onCopy: () =>
                                _copy(context, code, 'Invite code copied'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: gap),
                Material(
                  color: _accent,
                  borderRadius: BorderRadius.circular(12),
                  elevation: 2,
                  child: InkWell(
                    onTap: code == '—' ? null : () => shareWinAppInvite(code),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: (11 * scale).clamp(9.0, 13.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/whatsapp_icon.png',
                            width: (22 * scale).clamp(18.0, 24.0),
                            height: (22 * scale).clamp(18.0, 24.0),
                          ),
                          SizedBox(width: 10 * scale),
                          Text(
                            'ഷെയർ ചെയ്യൂ, വിജയിക്കൂ!',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: (15.5 * scale).clamp(13.0, 16.0),
                              fontWeight: FontWeight.w800,
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
        },
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

class _ReferCardBody extends StatelessWidget {
  const _ReferCardBody({
    required this.code,
    required this.scale,
    required this.onCopy,
  });

  final String code;
  final double scale;
  final VoidCallback onCopy;

  double _s(double value) => value * scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/mohanlal.png',
          height: _s(168),
          fit: BoxFit.contain,
        ),
        SizedBox(height: _s(4)),
        Text(
          'നിങ്ങളുടെ സ്വന്തം Agent',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF111827),
            fontSize: _s(16),
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        SizedBox(height: _s(6)),
        Text(
          'വേണ്ടത് ഇത്ര മാത്രം — നിങ്ങളുടെ മൂന്നക്ക നമ്പർ ലോട്ടറി എഴുത്തുകാരായ സുഹൃത്തുക്കൾക്ക് Win App share ചെയ്യുക.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF1F2937),
            fontSize: _s(13),
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: _s(5)),
        Text(
          'അവരെ നമ്മുടെ ആപ്പിൽ അക്കൗണ്ട് create ചെയ്യിക്കുക. അവർ ആദ്യ deposit ചെയ്യുന്നത് മുതൽ നിങ്ങൾക്ക് വരുമാനം കിട്ടി തുടങ്ങുന്നതാണ്.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF1F2937),
            fontSize: _s(13),
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: _s(8)),
        _BenefitItem(
          icon: Icons.card_giftcard_outlined,
          text: 'സുഹൃത്തിന് ₹50 വെൽക്കം ബോണസ്!',
          scale: scale,
        ),
        SizedBox(height: _s(6)),
        _BenefitItem(
          icon: Icons.show_chart_rounded,
          text: 'നിങ്ങൾക്ക് 5% ലൈഫ് ടൈം കമ്മീഷൻ!',
          scale: scale,
        ),
        SizedBox(height: _s(8)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '₹',
              style: TextStyle(
                color: ReferAndEarnView._accent,
                fontSize: _s(20),
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: _s(8)),
            Icon(
              Icons.sync_rounded,
              color: ReferAndEarnView._accent,
              size: _s(20),
            ),
            SizedBox(width: _s(8)),
            Text(
              '₹',
              style: TextStyle(
                color: ReferAndEarnView._accent,
                fontSize: _s(20),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        SizedBox(height: _s(4)),
        Text(
          '(അവർ പണം ചേർക്കുമ്പോൾ നിങ്ങൾക്ക് ലഭിക്കുന്നത്. ഉദാഹരണത്തിന്: ₹600 ചേർത്താൽ, നിങ്ങൾക്ക് ₹30)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF4B5563),
            fontSize: _s(11.5),
            height: 1.2,
          ),
        ),
        SizedBox(height: _s(8)),
        Text(
          'നിങ്ങളുടെ ഇൻവൈറ്റ് കോഡ്:',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF111827),
            fontSize: _s(13.5),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: _s(5)),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          elevation: 1,
          child: InkWell(
            onTap: code == '—' ? null : onCopy,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: _s(12),
                vertical: _s(7),
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
                      style: TextStyle(
                        color: const Color(0xFF111827),
                        fontSize: _s(18),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  SizedBox(width: _s(8)),
                  Icon(
                    Icons.copy_rounded,
                    color: const Color(0xFF6B7280),
                    size: _s(17),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.icon,
    required this.text,
    required this.scale,
  });

  final IconData icon;
  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: ReferAndEarnView._accent, size: 22 * scale),
        SizedBox(height: 4 * scale),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF111827),
            fontSize: 13.5 * scale,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
