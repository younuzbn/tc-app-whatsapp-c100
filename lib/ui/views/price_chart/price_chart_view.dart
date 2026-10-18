import 'package:flutter/material.dart';

import '../../../services/page_content_defaults.dart';
import '../../theme/win_theme.dart';
import '../../widgets/page_content_edit.dart';

class PriceChartView extends StatelessWidget {
  const PriceChartView({
    super.key,
    this.embedded = false,
    this.editable = false,
  });

  final bool embedded;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    return PageContentHost(
      pageKey: kPriceChartPageKey,
      editing: editable,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: WinTheme.bg,
          appBar: embedded
              ? null
              : AppBar(
                  backgroundColor: WinTheme.bg,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  title: const PageText(
                    'pageTitle',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
          body: Column(
            children: [
              if (editable) const PageEditBanner(),
              const Expanded(child: _PriceChartBody()),
            ],
          ),
        );
      },
    );
  }
}

class _PriceChartBody extends StatelessWidget {
  const _PriceChartBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: const [
        _Header(),
        _SuperTicketSection(),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AbcTicketsCard(),
              SizedBox(height: 10),
              _BoxPair(leftField: 'pair1Left', rightField: 'pair1Right'),
              SizedBox(height: 12),
              _SectionTitle(
                titleField: 'repeat2Title',
                subtitleField: 'repeat2Subtitle',
              ),
              SizedBox(height: 8),
              _BoxPair(leftField: 'pair2Left', rightField: 'pair2Right'),
              SizedBox(height: 12),
              _SectionTitle(
                titleField: 'tripleTitle',
                subtitleField: 'tripleSubtitle',
              ),
              SizedBox(height: 8),
              _TripleBanner(),
              SizedBox(height: 10),
              _MultiPrizeNote(),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      color: WinTheme.bg,
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PageText('headerEmoji', style: TextStyle(fontSize: 18)),
              SizedBox(width: 6),
              PageText(
                'headerTitle',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          PageText(
            'headerSubtitle',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: WinTheme.muted,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuperTicketSection extends StatelessWidget {
  const _SuperTicketSection();

  static const _prizes = <(String, String, String)>[
    ('prize1Title', 'prize1Amount', 'prize1Note'),
    ('prize2Title', 'prize2Amount', 'prize2Note'),
    ('prize3Title', 'prize3Amount', 'prize3Note'),
    ('prize4Title', 'prize4Amount', 'prize4Note'),
    ('prize5Title', 'prize5Amount', 'prize5Note'),
    ('prize6Title', 'prize6Amount', 'prize6Note'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Column(
        children: [
          const PageText(
            'superTitle',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: WinTheme.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const PageText(
              'ticketPrice',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < _prizes.length; i++) ...[
            _PrizeRow(
              titleField: _prizes[i].$1,
              amountField: _prizes[i].$2,
              noteField: _prizes[i].$3,
              featured: i == 0,
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _PrizeRow extends StatelessWidget {
  const _PrizeRow({
    required this.titleField,
    required this.amountField,
    required this.noteField,
    this.featured = false,
  });

  final String titleField;
  final String amountField;
  final String noteField;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: featured ? WinTheme.greenSoft : WinTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: featured ? WinTheme.green : WinTheme.border,
        ),
      ),
      child: Row(
        children: [
          if (featured) ...[
            const Icon(Icons.star_rounded, color: WinTheme.gold, size: 16),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageText(
                  titleField,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                PageText(
                  noteField,
                  hideIfEmpty: true,
                  placeholder: 'Tap to add note',
                  style: const TextStyle(
                    color: WinTheme.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          PageText(
            amountField,
            style: TextStyle(
              color: featured ? WinTheme.gold : WinTheme.green,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _AbcTicketsCard extends StatelessWidget {
  const _AbcTicketsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WinTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WinTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: const Column(
        children: [
          ColoredBox(
            color: WinTheme.greenSoft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: WinTheme.green, width: 3),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: PageText(
                        'abcTitle',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    PageText(
                      'abcSubtitle',
                      style: TextStyle(
                        color: WinTheme.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                _AbcTicketRow(
                  titleField: 'singleTitle',
                  priceField: 'singlePrice',
                  prizeField: 'singlePrize',
                ),
                SizedBox(height: 8),
                _AbcTicketRow(
                  titleField: 'doubleTitle',
                  priceField: 'doublePrice',
                  prizeField: 'doublePrize',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AbcTicketRow extends StatelessWidget {
  const _AbcTicketRow({
    required this.titleField,
    required this.priceField,
    required this.prizeField,
  });

  final String titleField;
  final String priceField;
  final String prizeField;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: WinTheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageText(
                  titleField,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                PageText(
                  priceField,
                  style: const TextStyle(color: WinTheme.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const PageText(
                'prizeWord',
                style: TextStyle(color: WinTheme.muted, fontSize: 10),
              ),
              const SizedBox(height: 2),
              PageText(
                prizeField,
                style: const TextStyle(
                  color: WinTheme.green,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.titleField, required this.subtitleField});

  final String titleField;
  final String subtitleField;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageText(
          titleField,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        PageText(
          subtitleField,
          textAlign: TextAlign.center,
          style: const TextStyle(color: WinTheme.muted, fontSize: 11),
        ),
      ],
    );
  }
}

class _BoxPair extends StatelessWidget {
  const _BoxPair({required this.leftField, required this.rightField});

  final String leftField;
  final String rightField;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BoxCard(labelField: 'boxDirectLabel', amountField: leftField),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _BoxCard(
            labelField: 'boxChangedLabel',
            amountField: rightField,
          ),
        ),
      ],
    );
  }
}

class _BoxCard extends StatelessWidget {
  const _BoxCard({required this.labelField, required this.amountField});

  final String labelField;
  final String amountField;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: WinTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WinTheme.border),
      ),
      child: Column(
        children: [
          PageText(
            labelField,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: WinTheme.muted, fontSize: 11),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: PageText(
              amountField,
              style: const TextStyle(
                color: WinTheme.green,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripleBanner extends StatelessWidget {
  const _TripleBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: WinTheme.greenSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WinTheme.green),
      ),
      child: const Row(
        children: [
          Expanded(
            child: PageText(
              'triplePrizeTitle',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          PageText(
            'tripleAmount',
            style: TextStyle(
              color: WinTheme.gold,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          PageText(
            'tripleSuffix',
            style: TextStyle(
              color: WinTheme.gold,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _MultiPrizeNote extends StatelessWidget {
  const _MultiPrizeNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WinTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WinTheme.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: WinTheme.green,
            child: Text(
              '!',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageText(
                  'noteTitle',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                PageText(
                  'noteBody',
                  style: TextStyle(
                    color: WinTheme.muted,
                    height: 1.3,
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 4),
                PageText(
                  'noteExample',
                  style: TextStyle(
                    color: WinTheme.muted,
                    height: 1.3,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
