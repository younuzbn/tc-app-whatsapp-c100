import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../home/game_chat_data.dart';

class AdminPositionDataView extends StatefulWidget {
  const AdminPositionDataView({super.key, this.game});

  final GameChatData? game;

  @override
  State<AdminPositionDataView> createState() => _AdminPositionDataViewState();
}

class _AdminPositionDataViewState extends State<AdminPositionDataView> {
  final _service = const AdminService();
  final _controllers = <String, TextEditingController>{};
  PositionDataConfig? _config;
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
      _config = await _service.getAdminPositionData();
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
    for (final entry in config.entries.entries) {
      _controllers.putIfAbsent('${entry.key}Rate', TextEditingController.new).text =
          entry.value.rate.toStringAsFixed(
            entry.value.rate.truncateToDouble() == entry.value.rate ? 0 : 2,
          );
    }
  }

  Future<void> _save() async {
    final config = _config;
    if (config == null) return;
    setState(() => _saving = true);
    try {
      final updatedEntries = <String, PositionEntry>{};
      for (final key in config.entries.keys) {
        updatedEntries[key] = PositionEntry(
          rate: _read('${key}Rate'),
          dc: 0,
        );
      }
      final updated = PositionDataConfig(
        adminId: config.adminId,
        entries: updatedEntries,
      );
      await _service.updateAdminPositionData(updated);
      _config = updated;
      _message = 'Position data updated.';
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
    final config = _config;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.game == null
              ? 'Position Data'
              : 'Position Data - ${widget.game!.name}',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : config == null
          ? Center(child: Text(_message ?? 'Unable to load position data'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_message != null) ...[
                  Text(_message!, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 12),
                ],
                for (final key in config.entries.keys)
                  _positionCard(
                    label: key,
                    rateKey: '${key}Rate',
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving...' : 'Save Position Data'),
                ),
              ],
            ),
    );
  }

  Widget _positionCard({
    required String label,
    required String rateKey,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
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
