import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../services/result_service.dart';
import '../../theme/win_theme.dart';
import '../home/game_chat_data.dart';

class ResultDetailView extends StatefulWidget {
  const ResultDetailView({super.key, required this.result});

  final GameResultData result;

  @override
  State<ResultDetailView> createState() => _ResultDetailViewState();
}

class _ResultDetailViewState extends State<ResultDetailView> {
  late GameResultData _result;

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

  String get _shareText =>
      ResultService.formatResultAsText(_result, gameName: _game.name);

  Future<void> _share() async {
    await SharePlus.instance.share(ShareParams(text: _shareText));
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: constraints.maxHeight * 0.9,
                child: Column(
                  children: [
                    Container(
                      color: WinTheme.bg,
                      padding: const EdgeInsets.fromLTRB(4, 2, 8, 2),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          const Spacer(),
                          Material(
                            color: WinTheme.bg,
                            child: InkWell(
                              onTap: _share,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/whatsapp_icon.png',
                                      width: 22,
                                      height: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'SHARE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      color: _titleBar,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Text(
                        '${_game.name} ( $dateLabel )',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            for (var i = 0; i < top.length; i++)
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${i + 1}',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 10),
                                      child: Text(
                                        ':',
                                        style: TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 18,
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
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        'COMPLIMENTS',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 8,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                        child: Column(
                          children: [
                            for (var row = 0; row < 10; row++)
                              Expanded(
                                child: Row(
                                  children: [
                                    for (var col = 0; col < 3; col++)
                                      Expanded(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              top: row == 0
                                                  ? BorderSide.none
                                                  : const BorderSide(color: Color(0xFFD1D5DB)),
                                              left: col == 0
                                                  ? BorderSide.none
                                                  : const BorderSide(color: Color(0xFFD1D5DB)),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              () {
                                                final index = col * 10 + row;
                                                if (index >= compliments.length) {
                                                  return '';
                                                }
                                                return compliments[index];
                                              }(),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
