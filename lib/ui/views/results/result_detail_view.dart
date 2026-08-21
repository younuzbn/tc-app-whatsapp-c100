import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../services/result_service.dart';
import '../home/game_chat_data.dart';

class ResultDetailView extends StatefulWidget {
  const ResultDetailView({super.key, required this.result});

  final GameResultData result;

  @override
  State<ResultDetailView> createState() => _ResultDetailViewState();
}

class _ResultDetailViewState extends State<ResultDetailView> {
  final _service = const ResultService();
  late GameResultData _result;
  bool _loading = false;

  static const Color _brown = Color(0xFF6D4C2B);
  static const Color _shareBlue = Color(0xFF1B3A57);
  static const Color _liveRed = Color(0xFF8A1C1C);
  static const Color _orange = Color(0xFFE67E22);
  static const Color _titleBar = Color(0xFF163E4A);

  @override
  void initState() {
    super.initState();
    _result = widget.result;
  }

  GameChatData get _game => gameForTimeSlot(_result.timeSlot);

  DateTime get _displayDate =>
      (_result.resultDate ?? _result.createdAt ?? DateTime.now()).toLocal();

  String _dateStamp(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  String get _shareText => ResultService.formatResultAsText(_result);

  Future<void> _share() async {
    await SharePlus.instance.share(ShareParams(text: _shareText));
  }

  Future<void> _changeDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _displayDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() => _loading = true);
    try {
      final next = await _service.getResultForDate(
        timeSlot: _result.timeSlot,
        date: picked,
      );
      if (!mounted) return;
      if (next == null) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No result for ${_game.name} on ${_dateStamp(picked)}')),
        );
        return;
      }
      setState(() {
        _result = next;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = ResultService.orderedValues(_result, keys: ResultService.topFieldKeys);
    final compliments = ResultService.orderedValues(
      _result,
      keys: ResultService.bottomFieldKeys,
    );
    final dateLabel = _dateStamp(_displayDate);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: _brown,
              padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    color: const Color(0xFFD9D9D9),
                    child: Text(
                      _game.name,
                      style: const TextStyle(
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: _shareBlue,
                    child: InkWell(
                      onTap: _share,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Text(
                          'SHARE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _share,
                    icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 28),
                    tooltip: 'WhatsApp',
                  ),
                  IconButton(
                    onPressed: _share,
                    icon: const Icon(Icons.menu, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      children: [
                        Center(
                          child: Material(
                            color: _liveRed,
                            borderRadius: BorderRadius.circular(6),
                            child: InkWell(
                              onTap: _share,
                              borderRadius: BorderRadius.circular(6),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                                child: Text(
                                  'LIVE RESULT LINK',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              dateLabel,
                              style: const TextStyle(
                                color: _orange,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: _changeDate,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _orange,
                                side: const BorderSide(color: _orange),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: const Text(
                                'CHANGE DATE',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          color: _titleBar,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            '${_game.name} ( $dateLabel )',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            for (var i = 0; i < top.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${i + 1}',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: Text(
                                        ':',
                                        style: TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        top[i].isEmpty ? '—' : top[i],
                                        textAlign: TextAlign.left,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            'COMPLIMENTS',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Table(
                          border: TableBorder.symmetric(
                            inside: const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          children: [
                            for (var row = 0; row < 10; row++)
                              TableRow(
                                children: [
                                  for (var col = 0; col < 3; col++)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      child: Text(
                                        () {
                                          final index = col * 10 + row;
                                          if (index >= compliments.length) return '';
                                          return compliments[index];
                                        }(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
