import 'package:flutter/material.dart';

import '../../../services/sales_service.dart';
import '../../../services/winning_service.dart';
import '../../theme/win_theme.dart';
import '../home/game_chat_data.dart';

class MyEntriesView extends StatefulWidget {
  const MyEntriesView({super.key, this.game, this.embedded = false});

  final GameChatData? game;
  final bool embedded;

  @override
  State<MyEntriesView> createState() => _MyEntriesViewState();
}

class _MyEntriesViewState extends State<MyEntriesView> {
  static const int _pageSize = 30;
  final _sales = const SalesService();
  final _winnings = const WinningService();
  final _scrollController = ScrollController();
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  List<SalesRecord> _entries = [];
  Set<String> _wonIds = {};
  int _page = 1;
  int _pages = 1;
  int _total = 0;

  bool get _hasMore => _page < _pages;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loadingMore || !_hasMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _sales.getSales(
        timeSlot: widget.game?.timeSlot,
        page: 1,
        limit: _pageSize,
      );
      page.sales.sort((a, b) {
        final ad = a.createdDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.createdDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
      final wins = await _winnings.listMyWinnings(timeSlot: widget.game?.timeSlot);
      if (!mounted) return;
      setState(() {
        _entries = page.sales;
        _page = page.page;
        _pages = page.pages;
        _total = page.total;
        _wonIds = wins.map((w) => '${w.billNumber}-${w.number}-${w.lsk}').toSet();
        _loading = false;
      });
      _maybeLoadMoreIfShort();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final next = await _sales.getSales(
        timeSlot: widget.game?.timeSlot,
        page: _page + 1,
        limit: _pageSize,
      );
      if (!mounted) return;
      final existing = _entries.map((e) => e.id).toSet();
      final extra = next.sales.where((s) => !existing.contains(s.id)).toList();
      extra.sort((a, b) {
        final ad = a.createdDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.createdDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
      setState(() {
        _entries = [..._entries, ...extra];
        _page = next.page;
        _pages = next.pages;
        _total = next.total;
        _loadingMore = false;
      });
      _maybeLoadMoreIfShort();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _maybeLoadMoreIfShort() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (_scrollController.position.maxScrollExtent <= 0 && _hasMore) {
        _loadMore();
      }
    });
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: WinTheme.green));
    }
    return RefreshIndicator(
      color: WinTheme.green,
      onRefresh: _load,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _entries.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.game == null ? 'My Entries' : '${widget.game!.name} entries',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '$_total total.',
                    style: const TextStyle(color: WinTheme.muted),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                    ),
                  if (_entries.isEmpty && _error == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 32),
                      child: Center(
                        child: Text(
                          'No entries yet.',
                          style: TextStyle(color: WinTheme.muted),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }
          if (index == _entries.length + 1) {
            if (!_hasMore && !_loadingMore) {
              return const SizedBox(height: 8);
            }
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: WinTheme.green),
                ),
              ),
            );
          }
          final sale = _entries[index - 1];
          final won = _wonIds.contains('${sale.billNumber}-${sale.number}-${sale.lsk}');
          return _EntryCard(sale: sale, won: won);
        },
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
        title: const Text('My Entries'),
      ),
      body: _body(),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.sale, required this.won});

  final SalesRecord sale;
  final bool won;

  @override
  Widget build(BuildContext context) {
    final line =
        '${WinTheme.lskLabel(sale.lsk)} - ${sale.number} - ${sale.count} - ₹${WinTheme.rupee(sale.damount)}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: WinTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WinTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  WinTheme.drawLabel(sale.timeSlot),
                  style: const TextStyle(color: WinTheme.muted, fontSize: 13),
                ),
              ),
              Text(
                won ? 'WON' : 'Confirmed',
                style: TextStyle(
                  color: won ? WinTheme.gold : WinTheme.green,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            line,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Align(
            alignment: Alignment.centerRight,
            child: Icon(Icons.done_all, color: Color(0xFF53BDEB), size: 18),
          ),
        ],
      ),
    );
  }
}
