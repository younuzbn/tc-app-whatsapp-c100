import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';

class AdminAccountSummaryView extends StatefulWidget {
  const AdminAccountSummaryView({super.key});

  @override
  State<AdminAccountSummaryView> createState() =>
      _AdminAccountSummaryViewState();
}

class _AdminAccountSummaryViewState extends State<AdminAccountSummaryView> {
  static const Color _bg = Color(0xFF0B141A);
  static const Color _surface = Color(0xFF111B21);
  static const Color _card = Color(0xFF1A2329);
  static const Color _line = Color(0xFF2A3942);
  static const Color _muted = Color(0xFF8696A0);
  static const Color _green = Color(0xFF25D366);
  static const Color _cream = Color(0xFFE9EDEF);

  static const List<_GameOption> _games = [
    _GameOption(timeSlot: 'all', label: 'All games'),
    _GameOption(timeSlot: '1pm', label: 'Dear 1 PM'),
    _GameOption(timeSlot: '3pm', label: 'Kerala 3 PM'),
    _GameOption(timeSlot: '6pm', label: 'Dear 6 PM'),
    _GameOption(timeSlot: '8pm', label: 'Dear 8 PM'),
  ];

  final _service = const AdminService();
  String _timeSlot = 'all';
  late String _fromDate;
  late String _toDate;
  bool _loading = true;
  String? _error;
  AccountSummaryReport? _report;

  @override
  void initState() {
    super.initState();
    final today = _todayYmd();
    _fromDate = today;
    _toDate = today;
    _load();
  }

  static String _todayYmd() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static String formatYmdIndian(String ymd) {
    final p = ymd.trim().split(RegExp(r'[-/]'));
    if (p.length != 3) return ymd;
    if (p[0].length == 4) {
      return '${p[2].padLeft(2, '0')}-${p[1].padLeft(2, '0')}-${p[0]}';
    }
    return ymd;
  }

  String _rupee(String raw) {
    final n = double.tryParse(raw) ?? 0;
    if (n.truncateToDouble() == n) return '₹${n.toStringAsFixed(0)}';
    return '₹${n.toStringAsFixed(2)}';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await _service.getAccountSummary(
        timeSlot: _timeSlot,
        fromDate: _fromDate,
        toDate: _toDate,
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _pickDate({required bool from}) async {
    final initial =
        DateTime.tryParse(from ? _fromDate : _toDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _green,
              onPrimary: Colors.black,
              surface: _surface,
              onSurface: _cream,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    final ymd =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() {
      if (from) {
        _fromDate = ymd;
        if (_fromDate.compareTo(_toDate) > 0) _toDate = _fromDate;
      } else {
        _toDate = ymd;
        if (_toDate.compareTo(_fromDate) < 0) _fromDate = _toDate;
      }
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final totals = _report?.totals;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _cream,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Account summary',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _timeSlot,
                  isExpanded: true,
                  dropdownColor: _surface,
                  iconEnabledColor: _muted,
                  style: const TextStyle(
                    color: _cream,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _surface,
                    labelText: 'Game',
                    labelStyle: const TextStyle(color: _muted),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _green),
                    ),
                  ),
                  items: [
                    for (final game in _games)
                      DropdownMenuItem<String>(
                        value: game.timeSlot,
                        child: Text(game.label),
                      ),
                  ],
                  onChanged: (slot) {
                    if (slot == null || slot == _timeSlot) return;
                    setState(() => _timeSlot = slot);
                    _load();
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _dateChip(
                        caption: 'From',
                        label: formatYmdIndian(_fromDate),
                        onTap: () => _pickDate(from: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dateChip(
                        caption: 'To',
                        label: formatYmdIndian(_toDate),
                        onTap: () => _pickDate(from: false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _green))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFF8A80),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: _green,
                        backgroundColor: _surface,
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _metricCard(
                                    label: 'Sales',
                                    value: _rupee(
                                      totals?.totalSalesAmount ?? '0',
                                    ),
                                    color: _green,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _metricCard(
                                    label: 'Winnings',
                                    value: _rupee(
                                      totals?.totalWinningAmount ?? '0',
                                    ),
                                    color: const Color(0xFFFACC15),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _metricCard(
                                    label: 'Balance',
                                    value: AccountSummaryRow.formatSignedAmount(
                                      totals?.balanceDouble ?? 0,
                                    ),
                                    color: (totals?.balanceDouble ?? 0) < 0
                                        ? const Color(0xFFEF6B6B)
                                        : _green,
                                    prefixRupee: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'By date',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._dayRows(),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  List<Widget> _dayRows() {
    final rows = _report?.rows.where((row) => row.hasActivity).toList() ??
        const <AccountSummaryRow>[];
    if (rows.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
          ),
          child: const Text(
            'No sales or winnings in this range.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 13),
          ),
        ),
      ];
    }
    return [
      for (final row in rows)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatYmdIndian(row.date),
                style: const TextStyle(
                  color: _cream,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _miniStat('Sale', _rupee(row.totalSalesAmount)),
                  _miniStat('Win', _rupee(row.totalWinningAmount)),
                  _miniStat('Bal', row.balanceSigned, highlight: true),
                ],
              ),
            ],
          ),
        ),
    ];
  }

  Widget _miniStat(String label, String value, {bool highlight = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: highlight ? _green : _cream,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required Color color,
    bool prefixRupee = false,
  }) {
    final shown = prefixRupee && !value.contains('₹') ? '₹$value' : value;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            shown,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateChip({
    required String caption,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caption,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: const TextStyle(
                        color: _cream,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.event, size: 18, color: _green),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameOption {
  const _GameOption({required this.timeSlot, required this.label});

  final String timeSlot;
  final String label;
}
