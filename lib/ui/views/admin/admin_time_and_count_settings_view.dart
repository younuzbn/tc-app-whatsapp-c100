import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';

class AdminTimeAndCountSettingsView extends StatefulWidget {
  const AdminTimeAndCountSettingsView({
    super.key,
    this.timeSlotFilter,
    this.gameTitle,
  });

  final String? timeSlotFilter;
  /// Game display name (e.g. DEAR 6PM) — shown in the app bar with the slot.
  final String? gameTitle;

  @override
  State<AdminTimeAndCountSettingsView> createState() =>
      _AdminTimeAndCountSettingsViewState();
}

class _AdminTimeAndCountSettingsViewState
    extends State<AdminTimeAndCountSettingsView> {
  final _service = const AdminService();
  bool _loading = true;
  bool _saving = false;
  String? _message;
  List<TimeAndCountSetting> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showBlockingSpinner = true}) async {
    if (showBlockingSpinner) {
      setState(() => _loading = true);
    }
    try {
      final filter = widget.timeSlotFilter?.trim();
      if (filter == null || filter.isEmpty) {
        _items = await _service.getTimeAndCountSettings();
        _message = null;
      } else {
        final normalized = filter.toLowerCase();
        if (!_isValidTimeSlot(normalized)) {
          _items = [];
          _message = 'Invalid time slot "$filter".';
        } else {
          final direct = await _service.getTimeAndCountSettingByTimeSlot(normalized);
          if (direct != null) {
            _items = [direct];
            _message = null;
          } else {
            // Do not show other slots' rows here — that made users edit 1pm while thinking it was 3pm.
            _items = [_newSlotTemplate(normalized)];
            _message =
                'No settings saved for $normalized yet. Defaults are filled in — adjust and tap Save to create this slot.';
          }
        }
      }
    } catch (error) {
      _message = error.toString().replaceFirst('Exception: ', '');
      _items = [];
    } finally {
      if (mounted) {
        setState(() {
          if (showBlockingSpinner) _loading = false;
        });
      }
    }
  }

  static const _allowedSlots = {'1pm', '2pm', '3pm', '6pm', '8pm'};

  bool _isValidTimeSlot(String normalized) => _allowedSlots.contains(normalized);

  /// HH:mm defaults valid for backend; [slotLower] must be a known slot id.
  TimeAndCountSetting _newSlotTemplate(String slotLower) {
    return TimeAndCountSetting(
      timeSlot: slotLower,
      openTime: '09:00',
      closeTime: '15:00',
      deletionTime: '15:00',
      fillTime: '15:00',
      singleLimitEnabled: false,
      singleLimitValue: 0,
      doubleLimitEnabled: false,
      doubleLimitValue: 0,
      boxLimitEnabled: false,
      boxLimitValue: 0,
      superLimitEnabled: false,
      superLimitValue: 0,
      saleChatSecondBanner: '',
    );
  }

  Future<void> _save(TimeAndCountSetting item) async {
    setState(() => _saving = true);
    try {
      await _service.saveTimeAndCountSetting(item);
      await _load(showBlockingSpinner: false);
      if (mounted) {
        setState(() {
          _message = '${item.timeSlot.toUpperCase()} saved.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _message = error.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.timeSlotFilter == null || widget.timeSlotFilter!.trim().isEmpty
              ? 'Time And Count Settings'
              : widget.gameTitle != null && widget.gameTitle!.trim().isNotEmpty
              ? '${widget.gameTitle!.trim()} · ${widget.timeSlotFilter!.trim().toUpperCase()}'
              : '${widget.timeSlotFilter!.trim().toUpperCase()} Time & Count',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _message ?? 'Nothing to show.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_message != null) ...[
                  Text(_message!, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 12),
                ],
                for (var i = 0; i < _items.length; i++) ...[
                  _SettingCard(
                    key: ValueKey(_items[i].timeSlot),
                    item: _items[i],
                    saving: _saving,
                    onChanged: (updated) => setState(() => _items[i] = updated),
                    onSave: () => _save(_items[i]),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class _SettingCard extends StatefulWidget {
  const _SettingCard({
    super.key,
    required this.item,
    required this.saving,
    required this.onChanged,
    required this.onSave,
  });

  final TimeAndCountSetting item;
  final bool saving;
  final ValueChanged<TimeAndCountSetting> onChanged;
  final VoidCallback onSave;

  @override
  State<_SettingCard> createState() => _SettingCardState();
}

class _SettingCardState extends State<_SettingCard> {
  late final TextEditingController _openController;
  late final TextEditingController _closeController;
  late final TextEditingController _singleController;
  late final TextEditingController _doubleController;
  late final TextEditingController _boxController;
  late final TextEditingController _superController;
  late final TextEditingController _secondBannerController;

  @override
  void initState() {
    super.initState();
    _openController = TextEditingController(text: widget.item.openTime);
    _closeController = TextEditingController(text: widget.item.closeTime);
    _singleController =
        TextEditingController(text: widget.item.singleLimitValue.toString());
    _doubleController =
        TextEditingController(text: widget.item.doubleLimitValue.toString());
    _boxController =
        TextEditingController(text: widget.item.boxLimitValue.toString());
    _superController =
        TextEditingController(text: widget.item.superLimitValue.toString());
    _secondBannerController = TextEditingController(
      text: widget.item.saleChatSecondBanner ?? '',
    );
  }

  @override
  void dispose() {
    _openController.dispose();
    _closeController.dispose();
    _singleController.dispose();
    _doubleController.dispose();
    _boxController.dispose();
    _superController.dispose();
    _secondBannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.timeSlot.toUpperCase(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _textField('Opening time', _openController),
            _textField('Closing time', _closeController),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _secondBannerController,
                keyboardType: TextInputType.multiline,
                minLines: 2,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Sale chat — second yellow banner',
                  helperText:
                      'Shown under the welcome banner on the customer sale page for this slot. Leave empty to hide.',
                ),
              ),
            ),
            _switchTile(
              'Single Limit',
              item.singleLimitEnabled,
              (value) => _update(item.copyWith(singleLimitEnabled: value)),
            ),
            _textField('Single Limit Value', _singleController),
            _switchTile(
              'Double Limit',
              item.doubleLimitEnabled,
              (value) => _update(item.copyWith(doubleLimitEnabled: value)),
            ),
            _textField('Double Limit Value', _doubleController),
            _switchTile(
              'Box Limit',
              item.boxLimitEnabled,
              (value) => _update(item.copyWith(boxLimitEnabled: value)),
            ),
            _textField('Box Limit Value', _boxController),
            _switchTile(
              'Super Limit',
              item.superLimitEnabled,
              (value) => _update(item.copyWith(superLimitEnabled: value)),
            ),
            _textField('Super Limit Value', _superController),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: widget.saving
                  ? null
                  : () {
                      final close = _closeController.text.trim();
                      _update(
                        item.copyWith(
                          openTime: _openController.text.trim(),
                          closeTime: close,
                          deletionTime: close,
                          fillTime: close,
                          saleChatSecondBanner:
                              _secondBannerController.text.trim(),
                          singleLimitValue:
                              int.tryParse(_singleController.text.trim()) ?? 0,
                          doubleLimitValue:
                              int.tryParse(_doubleController.text.trim()) ?? 0,
                          boxLimitValue:
                              int.tryParse(_boxController.text.trim()) ?? 0,
                          superLimitValue:
                              int.tryParse(_superController.text.trim()) ?? 0,
                        ),
                      );
                      widget.onSave();
                    },
              child: const Text('Save Slot'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _switchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      title: Text(title),
      onChanged: onChanged,
    );
  }

  void _update(TimeAndCountSetting updated) {
    widget.onChanged(updated);
  }
}

extension on TimeAndCountSetting {
  TimeAndCountSetting copyWith({
    String? openTime,
    String? closeTime,
    String? deletionTime,
    String? fillTime,
    String? saleChatSecondBanner,
    bool? singleLimitEnabled,
    int? singleLimitValue,
    bool? doubleLimitEnabled,
    int? doubleLimitValue,
    bool? boxLimitEnabled,
    int? boxLimitValue,
    bool? superLimitEnabled,
    int? superLimitValue,
  }) {
    return TimeAndCountSetting(
      timeSlot: timeSlot,
      closeTime: closeTime ?? this.closeTime,
      openTime: openTime ?? this.openTime,
      deletionTime: deletionTime ?? this.deletionTime,
      fillTime: fillTime ?? this.fillTime,
      saleChatSecondBanner:
          saleChatSecondBanner ?? this.saleChatSecondBanner,
      singleLimitEnabled: singleLimitEnabled ?? this.singleLimitEnabled,
      singleLimitValue: singleLimitValue ?? this.singleLimitValue,
      doubleLimitEnabled: doubleLimitEnabled ?? this.doubleLimitEnabled,
      doubleLimitValue: doubleLimitValue ?? this.doubleLimitValue,
      boxLimitEnabled: boxLimitEnabled ?? this.boxLimitEnabled,
      boxLimitValue: boxLimitValue ?? this.boxLimitValue,
      superLimitEnabled: superLimitEnabled ?? this.superLimitEnabled,
      superLimitValue: superLimitValue ?? this.superLimitValue,
    );
  }
}
