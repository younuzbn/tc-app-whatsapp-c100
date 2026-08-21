import 'package:flutter/material.dart';

import '../../../services/winning_service.dart';
import '../../theme/win_theme.dart';
import '../home/game_chat_data.dart';

class WinningChatView extends StatefulWidget {
  const WinningChatView({super.key, this.game, this.embedded = false});

  final GameChatData? game;
  final bool embedded;

  @override
  State<WinningChatView> createState() => _WinningChatViewState();
}

class _WinningChatViewState extends State<WinningChatView> {
  final _service = const WinningService();
  bool _loading = true;
  String? _error;
  List<WinningReport> _reports = [];

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
      final list = await _service.listMyWinnings(timeSlot: widget.game?.timeSlot);
      list.sort((a, b) {
        final ad = a.resultDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.resultDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
      if (!mounted) return;
      setState(() {
        _reports = list;
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
            'Winnings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          if (_reports.isEmpty && _error == null)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Text(
                'No winnings yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: WinTheme.muted),
              ),
            ),
          ..._reports.map((report) => _WinningCard(report: report)),
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
        elevation: 0,
        title: const Text('Winnings'),
      ),
      body: _body(),
    );
  }
}

class _WinningCard extends StatelessWidget {
  const _WinningCard({required this.report});

  final WinningReport report;

  @override
  Widget build(BuildContext context) {
    final line =
        '${WinTheme.lskLabel(report.lsk)} - ${report.number} - ${report.count} - ₹${WinTheme.rupee(report.winAmount > 0 ? report.winAmount : report.positionRate * report.count)}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: WinTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WinTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  WinTheme.drawLabel(report.timeSlot),
                  style: const TextStyle(color: WinTheme.muted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  line,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: WinTheme.gold,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.emoji_events, size: 16, color: Colors.black),
                SizedBox(width: 4),
                Text(
                  'WON',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
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
