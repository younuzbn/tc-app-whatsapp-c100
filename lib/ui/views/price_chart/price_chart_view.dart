import 'package:flutter/material.dart';

import '../../theme/win_theme.dart';

class PriceChartView extends StatelessWidget {
  const PriceChartView({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WinTheme.bg,
      appBar: embedded
          ? null
          : AppBar(
              backgroundColor: WinTheme.bg,
              foregroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'സമ്മാന ചാർട്ട്',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
      body: const _PriceChartBody(),
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
          padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AbcTicketsCard(),
              SizedBox(height: 16),
              _BoxPair(
                leftAmount: '₹3,300',
                rightAmount: '₹800',
              ),
              SizedBox(height: 18),
              _SectionTitle(
                title: '2 അക്കങ്ങൾ ആവർത്തിച്ചാൽ',
                subtitle: '(ഉദാ: 556, 667)',
              ),
              SizedBox(height: 10),
              _BoxPair(
                leftAmount: '₹3,800',
                rightAmount: '₹800',
              ),
              SizedBox(height: 18),
              _SectionTitle(
                title: '3 അക്കങ്ങളും ഒന്നായാൽ',
                subtitle: '(ഉദാ: 666, 444, 777)',
              ),
              SizedBox(height: 10),
              _TripleBanner(),
              SizedBox(height: 16),
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
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      color: WinTheme.bg,
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🏆', style: TextStyle(fontSize: 22)),
              SizedBox(width: 8),
              Text(
                'സമ്മാന ചാർട്ട്',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'നിങ്ങളുടെ വിജയ വിവരങ്ങൾ ഇവിടെ കാണാം',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: WinTheme.muted,
              fontSize: 13,
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

  static const _prizes = <(String, String, String?)>[
    ('ഒന്നാം സമ്മാനം', '₹5,000', null),
    ('രണ്ടാം സമ്മാനം', '₹500', null),
    ('മൂന്നാം സമ്മാനം', '₹250', null),
    ('നാലാം സമ്മാനം', '₹100', null),
    ('അഞ്ചാം സമ്മാനം', '₹50', null),
    ('ആറാം സമ്മാനം', '₹30', '(30 വ്യത്യസ്ത നമ്പറുകൾക്ക്)'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          const Text(
            '3 അക്ക സൂപ്പർ ടിക്കറ്റ്',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: WinTheme.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'ടിക്കറ്റ് വില: ₹10',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < _prizes.length; i++) ...[
            _PrizeRow(
              title: _prizes[i].$1,
              amount: _prizes[i].$2,
              note: _prizes[i].$3,
              featured: i == 0,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _PrizeRow extends StatelessWidget {
  const _PrizeRow({
    required this.title,
    required this.amount,
    this.note,
    this.featured = false,
  });

  final String title;
  final String amount;
  final String? note;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: featured ? WinTheme.greenSoft : WinTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: featured ? WinTheme.green : WinTheme.border,
        ),
      ),
      child: Row(
        children: [
          if (featured) ...[
            const Icon(Icons.star_rounded, color: WinTheme.gold, size: 20),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (note != null)
                  Text(
                    note!,
                    style: const TextStyle(
                      color: WinTheme.muted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: featured ? WinTheme.gold : WinTheme.green,
              fontWeight: FontWeight.w800,
              fontSize: 20,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WinTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              color: WinTheme.greenSoft,
              border: Border(
                top: BorderSide(color: WinTheme.green, width: 4),
              ),
            ),
            child: const Column(
              children: [
                Text(
                  'എ, ബി, സി (A, B, C)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'ടിക്കറ്റുകൾ',
                  style: TextStyle(
                    color: WinTheme.green,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Column(
              children: [
                _AbcTicketRow(
                  title: 'സിംഗിൾ ടിക്കറ്റ് (A, B, C)',
                  price: 'ടിക്കറ്റ് വില: ₹12',
                  prize: '₹100',
                ),
                SizedBox(height: 10),
                _AbcTicketRow(
                  title: 'ഡബിൾ ടിക്കറ്റ് (AB, BC, AC)',
                  price: 'ടിക്കറ്റ് വില: ₹10',
                  prize: '₹700',
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
    required this.title,
    required this.price,
    required this.prize,
  });

  final String title;
  final String price;
  final String prize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: WinTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: const TextStyle(color: WinTheme.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'സമ്മാനം',
                style: TextStyle(color: WinTheme.muted, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                prize,
                style: const TextStyle(
                  color: WinTheme.green,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
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
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: WinTheme.muted, fontSize: 13),
        ),
      ],
    );
  }
}

class _BoxPair extends StatelessWidget {
  const _BoxPair({required this.leftAmount, required this.rightAmount});

  final String leftAmount;
  final String rightAmount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BoxCard(label: 'നേരിട്ട് വന്നാൽ', amount: leftAmount),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _BoxCard(label: 'മാറി വന്നാൽ (ബോക്സ്)', amount: rightAmount),
        ),
      ],
    );
  }
}

class _BoxCard extends StatelessWidget {
  const _BoxCard({required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: WinTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WinTheme.border),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: WinTheme.muted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(
              color: WinTheme.green,
              fontSize: 24,
              fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: WinTheme.greenSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WinTheme.green),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              'ഒന്നാം സമ്മാനം',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '₹7,000',
                  style: TextStyle(
                    color: WinTheme.gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
                TextSpan(
                  text: ' (box)',
                  style: TextStyle(
                    color: WinTheme.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
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

class _MultiPrizeNote extends StatelessWidget {
  const _MultiPrizeNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: WinTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WinTheme.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: WinTheme.green,
            child: Text(
              '!',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ഒന്നിലധികം സമ്മാനങ്ങൾ ലഭിച്ചാൽ:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'ഒരേ നമ്പർ തന്നെ പല സമ്മാനങ്ങൾക്ക് അർഹമായാൽ, എല്ലാ സമ്മാനത്തുകയും ഒരുമിച്ച് ലഭിക്കുന്നതാണ്.',
                  style: TextStyle(
                    color: WinTheme.muted,
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '(ഉദാഹരണത്തിന്: 123 എന്ന നമ്പറിന് ഒന്നാമത്തെയും രണ്ടാമത്തെയും സമ്മാനം ലഭിച്ചാൽ ₹5000 + ₹500 = ₹5500 ലഭിക്കും).',
                  style: TextStyle(
                    color: WinTheme.muted,
                    height: 1.4,
                    fontSize: 13,
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
