import 'package:flutter/material.dart';

import '../../../services/result_service.dart';
import '../../theme/win_theme.dart';
import '../home/game_chat_data.dart';
import 'result_detail_view.dart';

class ResultsListView extends StatefulWidget {
  const ResultsListView({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ResultsListView> createState() => _ResultsListViewState();
}

class _ResultsListViewState extends State<ResultsListView> {
  final _service = const ResultService();
  bool _loading = true;
  String? _error;
  List<GameResultData> _results = [];

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
      final list = await _service.listAllResults(limit: 80);
      list.sort((a, b) {
        final ad = a.createdAt ?? a.resultDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.createdAt ?? b.resultDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
      if (!mounted) return;
      setState(() {
        _results = list;
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

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: WinTheme.green));
    }
    return RefreshIndicator(
      color: WinTheme.green,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Text(
            'Results',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          if (_results.isEmpty && _error == null)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Text(
                'No results published yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: WinTheme.muted),
              ),
            ),
          ..._results.map(
            (result) => _ResultCard(
              result: result,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ResultDetailView(result: result),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _body();
    return Scaffold(
      backgroundColor: WinTheme.bg,
      appBar: AppBar(
        backgroundColor: WinTheme.bg,
        foregroundColor: Colors.white,
        title: const Text('Results'),
      ),
      body: _body(),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.onTap});

  final GameResultData result;
  final VoidCallback onTap;

  String _publishedLabel() {
    final date = (result.createdAt ?? result.resultDate)?.toLocal();
    if (date == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    var hour = date.hour;
    final ampm = hour >= 12 ? 'pm' : 'am';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return 'Published ${date.day} ${months[date.month - 1]} at $hour:${date.minute.toString().padLeft(2, '0')} $ampm';
  }

  String _prize(String key) => result.fields[key] ?? '—';

  @override
  Widget build(BuildContext context) {
    final game = gameForTimeSlot(result.timeSlot);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: WinTheme.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WinTheme.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: game.avatarColor,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        game.avatarText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            WinTheme.drawLabel(result.timeSlot),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _publishedLabel(),
                            style: const TextStyle(
                              color: WinTheme.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: WinTheme.gold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'RESULT OUT',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _PrizeRow(label: '1st Prize', value: _prize('firstprice'), gold: true),
                const SizedBox(height: 8),
                _PrizeRow(label: '2nd Prize', value: _prize('secondprice')),
                const SizedBox(height: 8),
                _PrizeRow(label: '3rd Prize', value: _prize('thirdprice')),
                const SizedBox(height: 8),
                _PrizeRow(label: '4th Prize', value: _prize('fourthprice')),
                const SizedBox(height: 8),
                _PrizeRow(label: '5th Prize', value: _prize('fifthplace')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrizeRow extends StatelessWidget {
  const _PrizeRow({required this.label, required this.value, this.gold = false});

  final String label;
  final String value;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: WinTheme.muted, fontSize: 14)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: gold ? WinTheme.gold : Colors.white,
            fontSize: gold ? 22 : 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
