import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../services/result_service.dart';
import '../home/game_chat_data.dart';

/// Results-only chat for a game: same header/style as Draws chat,
/// incoming WhatsApp bubbles for each admin-published result.
class ResultsChatView extends StatefulWidget {
  const ResultsChatView({super.key, required this.game});

  final GameChatData game;

  @override
  State<ResultsChatView> createState() => _ResultsChatViewState();
}

class _ResultsChatViewState extends State<ResultsChatView> {
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
      final list = await _service.listResultsForTimeSlot(
        timeSlot: widget.game.timeSlot,
      );
      list.sort((a, b) {
        final ad = a.resultDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.resultDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ad.compareTo(bd);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE7DE),
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(game: widget.game),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF008069),
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF008069),
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                        children: [
                          const _SystemBanner(
                            text:
                                'Official results for this draw. Pull to refresh.',
                          ),
                          const SizedBox(height: 14),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (_results.isEmpty && _error == null)
                            const Padding(
                              padding: EdgeInsets.only(top: 24),
                              child: Text(
                                'No results published yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ..._results.map(
                            (result) => _IncomingResultBubble(result: result),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.game});

  final GameChatData game;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF008069),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: game.avatarColor.withValues(alpha: 0.35),
            child: Text(
              game.avatarText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Results',
                  style: TextStyle(color: Color(0xFFD8EFEA), fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SystemBanner extends StatelessWidget {
  const _SystemBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3C4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF5B4B16),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _IncomingResultBubble extends StatelessWidget {
  const _IncomingResultBubble({required this.result});

  final GameResultData result;

  @override
  Widget build(BuildContext context) {
    final top = ResultService.orderedValues(
      result,
      keys: ResultService.topFieldKeys,
    );
    final bottom = ResultService.orderedValues(
      result,
      keys: ResultService.bottomFieldKeys,
    );
    final bottomRows = <List<String>>[];
    for (var i = 0; i < bottom.length; i += 5) {
      bottomRows.add(bottom.sublist(i, i + 5));
    }

    final time = result.resultDate;
    final timeLabel = time == null
        ? ''
        : '${time.hour.toString().padLeft(2, '0')}:'
            '${time.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.92,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ResultService.formatResultDateLabel(result),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF008069),
                  ),
                ),
                const SizedBox(height: 8),
                _ValueRow(values: top),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, thickness: 1),
                ),
                for (var i = 0; i < bottomRows.length; i++) ...[
                  if (i > 0) const SizedBox(height: 4),
                  _ValueRow(values: bottomRows[i]),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (timeLabel.isNotEmpty)
                      Text(
                        timeLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Copy',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      onPressed: () async {
                        final text = ResultService.formatResultAsText(result);
                        await Clipboard.setData(ClipboardData(text: text));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Result copied')),
                        );
                      },
                      icon: const Icon(
                        Icons.copy_rounded,
                        size: 20,
                        color: Color(0xFF008069),
                      ),
                    ),
                    const SizedBox(width: 2),
                    TextButton.icon(
                      onPressed: () async {
                        final text = ResultService.formatResultAsText(result);
                        await SharePlus.instance.share(
                          ShareParams(text: text),
                        );
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF008069),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.values});

  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < values.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                values[i].isEmpty ? '·' : values[i],
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: values[i].isEmpty
                      ? const Color(0xFFD1D5DB)
                      : const Color(0xFF1F2937),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
