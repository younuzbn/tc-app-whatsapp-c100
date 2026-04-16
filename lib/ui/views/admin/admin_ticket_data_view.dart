import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../home/game_chat_data.dart';

class AdminTicketDataView extends StatefulWidget {
  const AdminTicketDataView({super.key, this.game});

  final GameChatData? game;

  @override
  State<AdminTicketDataView> createState() => _AdminTicketDataViewState();
}

class _AdminTicketDataViewState extends State<AdminTicketDataView> {
  final _service = const AdminService();
  final _controllers = <String, TextEditingController>{};
  MobileAppConfig? _config;
  bool _loading = true;
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _config = await _service.getAdminTicketData();
      _setControllers();
      _message = null;
    } catch (error) {
      _message = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setControllers() {
    final config = _config;
    if (config == null) return;
    _setValue('singleRate', config.single.rate);
    _setValue('doubleRate', config.doubleType.rate);
    _setValue('superRate', config.superType.rate);
    _setValue('boxRate', config.box.rate);
  }

  void _setValue(String key, double value) {
    _controllers.putIfAbsent(key, TextEditingController.new).text =
        value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  Future<void> _save() async {
    final config = _config;
    if (config == null) return;
    setState(() => _saving = true);
    try {
      final updated = MobileAppConfig(
        adminId: config.adminId,
        single: TicketEntry(
          rate: _read('singleRate'),
          dc: 0,
        ),
        doubleType: TicketEntry(
          rate: _read('doubleRate'),
          dc: 0,
        ),
        superType: TicketEntry(
          rate: _read('superRate'),
          dc: 0,
        ),
        box: TicketEntry(
          rate: _read('boxRate'),
          dc: 0,
        ),
        positionData: config.positionData,
        walletBalance: config.walletBalance,
      );
      await _service.updateAdminTicketData(updated);
      _config = updated;
      _message = 'Ticket data updated.';
    } catch (error) {
      _message = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double _read(String key) =>
      double.tryParse(_controllers[key]?.text.trim() ?? '') ?? 0;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.game == null
              ? 'Ticket Data'
              : 'Ticket Data - ${widget.game!.name}',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_message != null) ...[
                  Text(_message!, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 12),
                ],
                _entryCard('Single / 1D', 'singleRate'),
                _entryCard('Double / 2D', 'doubleRate'),
                _entryCard('Super / 3D-DEAR', 'superRate'),
                _entryCard('Box', 'boxRate'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving...' : 'Save Ticket Data'),
                ),
              ],
            ),
    );
  }

  Widget _entryCard(String title, String rateKey) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controllers.putIfAbsent(rateKey, TextEditingController.new),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Rate'),
            ),
          ],
        ),
      ),
    );
  }
}
