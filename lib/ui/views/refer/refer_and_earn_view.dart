import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/page_content_defaults.dart';
import '../../../services/referral_share.dart';
import '../../theme/win_theme.dart';
import '../../widgets/page_content_edit.dart';

class ReferAndEarnView extends StatelessWidget {
  const ReferAndEarnView({
    super.key,
    required this.referralCode,
    this.embedded = false,
    this.editable = false,
  });

  final String referralCode;
  final bool embedded;
  final bool editable;

  static const Color _headerBg = Color(0xFFFFFFFF);
  static const Color _accent = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    final code = referralCode.trim().isEmpty ? '—' : referralCode.trim();

    return PageContentHost(
      pageKey: kReferEarnPageKey,
      editing: editable,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: WinTheme.bg,
          resizeToAvoidBottomInset: false,
          appBar: embedded
              ? null
              : AppBar(
                  backgroundColor: WinTheme.bg,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  title: PageText(
                    'pageTitle',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
          body: Column(
            children: [
              if (editable) const PageEditBanner(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final scale = (constraints.maxHeight / 640).clamp(0.68, 1.0);
                    final side = 16.0 * scale;
                    final cardPad = 12.0 * scale;
                    final gap = 8.0 * scale;

                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        side,
                        6 * scale,
                        side,
                        6 * scale,
                      ),
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
                                      onCopy: () => _copy(
                                        context,
                                        code,
                                        'Invite code copied',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: gap),
                          _ShareButton(
                            code: code,
                            scale: scale,
                            editable: editable,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.code,
    required this.scale,
    required this.editable,
  });

  final String code;
  final double scale;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final label = PageText(
      'shareButtonLabel',
      style: TextStyle(
        color: Colors.black,
        fontSize: (15.5 * scale).clamp(13.0, 16.0),
        fontWeight: FontWeight.w800,
      ),
    );
    final icon = PageImage(
      field: 'shareIconUrl',
      assetFallback: 'assets/whatsapp_icon.png',
      width: (22 * scale).clamp(18.0, 24.0),
      height: (22 * scale).clamp(18.0, 24.0),
    );
    final row = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon,
        SizedBox(width: 10 * scale),
        Flexible(child: label),
      ],
    );
    return Material(
      color: ReferAndEarnView._accent,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: editable || code == '—'
            ? null
            : () => shareWinAppInvite(code),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: (11 * scale).clamp(9.0, 13.0),
          ),
          child: row,
        ),
      ),
    );
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
        PageImage(
          field: 'heroImageUrl',
          assetFallback: 'assets/mohanlal.png',
          height: _s(168),
        ),
        SizedBox(height: _s(4)),
        PageText(
          'title',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF111827),
            fontSize: _s(16),
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        SizedBox(height: _s(6)),
        PageText(
          'body1',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF1F2937),
            fontSize: _s(13),
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: _s(5)),
        PageText(
          'body2',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF1F2937),
            fontSize: _s(13),
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: _s(8)),
        _BenefitItem(iconField: 'benefit1Icon', textField: 'benefit1Text', scale: scale),
        SizedBox(height: _s(6)),
        _BenefitItem(iconField: 'benefit2Icon', textField: 'benefit2Text', scale: scale),
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
        PageText(
          'exampleNote',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF4B5563),
            fontSize: _s(11.5),
            height: 1.2,
          ),
        ),
        SizedBox(height: _s(8)),
        PageText(
          'inviteCodeLabel',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF111827),
            fontSize: _s(13.5),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: _s(5)),
        AutoGeneratedCodeBox(
          code: code,
          scale: scale,
          onCopy: onCopy,
        ),
      ],
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.iconField,
    required this.textField,
    required this.scale,
  });

  final String iconField;
  final String textField;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageIcon(
          iconField,
          color: ReferAndEarnView._accent,
          size: 22 * scale,
        ),
        SizedBox(height: 4 * scale),
        PageText(
          textField,
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
