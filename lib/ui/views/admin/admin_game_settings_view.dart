import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../home/game_chat_data.dart';

class AdminGameSettingsView extends StatefulWidget {
  const AdminGameSettingsView({super.key, this.game});

  final GameChatData? game;

  @override
  State<AdminGameSettingsView> createState() => _AdminGameSettingsViewState();
}

class _AdminGameSettingsViewState extends State<AdminGameSettingsView> {
  final _service = const AdminService();
  final _advanceController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _message;
  GameSettingsData? _settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getGameSettings();
      _settings = data;
      _advanceController.text = data.advanceBookingLimitValue.toString();
      _message = null;
    } catch (error) {
      _message = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final current = _settings;
    if (current == null) return;

    setState(() => _saving = true);
    try {
      final updated = GameSettingsData(
        advanceBookingLimit: current.advanceBookingLimit,
        advanceBookingLimitValue:
            int.tryParse(_advanceController.text.trim()) ?? 0,
        stopTheApp: current.stopTheApp,
        stopBooking1pm: current.stopBooking1pm,
        stopBooking3pm: current.stopBooking3pm,
        stopBooking6pm: current.stopBooking6pm,
        stopBooking8pm: current.stopBooking8pm,
        gameEnabled1pm: current.gameEnabled1pm,
        gameEnabled3pm: current.gameEnabled3pm,
        gameEnabled6pm: current.gameEnabled6pm,
        gameEnabled8pm: current.gameEnabled8pm,
      );
      await _service.updateGameSettings(updated);
      _settings = updated;
      _message = 'Game settings updated.';
    } catch (error) {
      _message = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _advanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    final slot = widget.game?.timeSlot;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.game == null
              ? 'Game Settings'
              : 'Game Settings - ${widget.game!.name}',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : settings == null
          ? Center(child: Text(_message ?? 'Unable to load settings'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_message != null) ...[
                  Text(_message!, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 12),
                ],
                SwitchListTile(
                  value: settings.stopTheApp,
                  title: const Text('Stop The App'),
                  onChanged: (value) =>
                      setState(() => _settings = _copy(settings, stopTheApp: value)),
                ),
                SwitchListTile(
                  value: settings.advanceBookingLimit,
                  title: const Text('Advance Booking Limit'),
                  onChanged: (value) => setState(
                    () => _settings = _copy(settings, advanceBookingLimit: value),
                  ),
                ),
                TextField(
                  controller: _advanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Advance Booking Limit Value',
                  ),
                ),
                const SizedBox(height: 8),
                if (slot != null) ...[
                  _boolTile(
                    '${widget.game!.name} Enabled',
                    _gameEnabledForSlot(settings, slot),
                    (value) => setState(
                      () => _settings = _setGameEnabledForSlot(settings, slot, value),
                    ),
                  ),
                  _boolTile(
                    'Stop ${widget.game!.name} Booking',
                    _stopBookingForSlot(settings, slot),
                    (value) => setState(
                      () => _settings = _setStopBookingForSlot(settings, slot, value),
                    ),
                  ),
                ] else ...[
                  _boolTile(
                    '1PM Game Enabled',
                    settings.gameEnabled1pm,
                    (value) => setState(
                      () => _settings = _copy(settings, gameEnabled1pm: value),
                    ),
                  ),
                  _boolTile(
                    '3PM Game Enabled',
                    settings.gameEnabled3pm,
                    (value) => setState(
                      () => _settings = _copy(settings, gameEnabled3pm: value),
                    ),
                  ),
                  _boolTile(
                    '6PM Game Enabled',
                    settings.gameEnabled6pm,
                    (value) => setState(
                      () => _settings = _copy(settings, gameEnabled6pm: value),
                    ),
                  ),
                  _boolTile(
                    '8PM Game Enabled',
                    settings.gameEnabled8pm,
                    (value) => setState(
                      () => _settings = _copy(settings, gameEnabled8pm: value),
                    ),
                  ),
                  _boolTile(
                    'Stop 1PM Booking',
                    settings.stopBooking1pm,
                    (value) => setState(
                      () => _settings = _copy(settings, stopBooking1pm: value),
                    ),
                  ),
                  _boolTile(
                    'Stop 3PM Booking',
                    settings.stopBooking3pm,
                    (value) => setState(
                      () => _settings = _copy(settings, stopBooking3pm: value),
                    ),
                  ),
                  _boolTile(
                    'Stop 6PM Booking',
                    settings.stopBooking6pm,
                    (value) => setState(
                      () => _settings = _copy(settings, stopBooking6pm: value),
                    ),
                  ),
                  _boolTile(
                    'Stop 8PM Booking',
                    settings.stopBooking8pm,
                    (value) => setState(
                      () => _settings = _copy(settings, stopBooking8pm: value),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving...' : 'Save'),
                ),
              ],
            ),
    );
  }

  Widget _boolTile(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(value: value, title: Text(title), onChanged: onChanged);
  }

  bool _gameEnabledForSlot(GameSettingsData settings, String slot) {
    switch (slot) {
      case '1pm':
        return settings.gameEnabled1pm;
      case '3pm':
        return settings.gameEnabled3pm;
      case '6pm':
        return settings.gameEnabled6pm;
      case '8pm':
      default:
        return settings.gameEnabled8pm;
    }
  }

  bool _stopBookingForSlot(GameSettingsData settings, String slot) {
    switch (slot) {
      case '1pm':
        return settings.stopBooking1pm;
      case '3pm':
        return settings.stopBooking3pm;
      case '6pm':
        return settings.stopBooking6pm;
      case '8pm':
      default:
        return settings.stopBooking8pm;
    }
  }

  GameSettingsData _setGameEnabledForSlot(
    GameSettingsData source,
    String slot,
    bool value,
  ) {
    switch (slot) {
      case '1pm':
        return _copy(source, gameEnabled1pm: value);
      case '3pm':
        return _copy(source, gameEnabled3pm: value);
      case '6pm':
        return _copy(source, gameEnabled6pm: value);
      case '8pm':
      default:
        return _copy(source, gameEnabled8pm: value);
    }
  }

  GameSettingsData _setStopBookingForSlot(
    GameSettingsData source,
    String slot,
    bool value,
  ) {
    switch (slot) {
      case '1pm':
        return _copy(source, stopBooking1pm: value);
      case '3pm':
        return _copy(source, stopBooking3pm: value);
      case '6pm':
        return _copy(source, stopBooking6pm: value);
      case '8pm':
      default:
        return _copy(source, stopBooking8pm: value);
    }
  }

  GameSettingsData _copy(
    GameSettingsData source, {
    bool? advanceBookingLimit,
    bool? stopTheApp,
    bool? stopBooking1pm,
    bool? stopBooking3pm,
    bool? stopBooking6pm,
    bool? stopBooking8pm,
    bool? gameEnabled1pm,
    bool? gameEnabled3pm,
    bool? gameEnabled6pm,
    bool? gameEnabled8pm,
  }) {
    return GameSettingsData(
      advanceBookingLimit: advanceBookingLimit ?? source.advanceBookingLimit,
      advanceBookingLimitValue: source.advanceBookingLimitValue,
      stopTheApp: stopTheApp ?? source.stopTheApp,
      stopBooking1pm: stopBooking1pm ?? source.stopBooking1pm,
      stopBooking3pm: stopBooking3pm ?? source.stopBooking3pm,
      stopBooking6pm: stopBooking6pm ?? source.stopBooking6pm,
      stopBooking8pm: stopBooking8pm ?? source.stopBooking8pm,
      gameEnabled1pm: gameEnabled1pm ?? source.gameEnabled1pm,
      gameEnabled3pm: gameEnabled3pm ?? source.gameEnabled3pm,
      gameEnabled6pm: gameEnabled6pm ?? source.gameEnabled6pm,
      gameEnabled8pm: gameEnabled8pm ?? source.gameEnabled8pm,
    );
  }
}
