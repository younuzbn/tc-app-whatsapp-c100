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
  late String _openTime;
  late String _closeTime;
  late final TextEditingController _singleController;
  late final TextEditingController _doubleController;
  late final TextEditingController _boxController;
  late final TextEditingController _superController;
  late final TextEditingController _secondBannerController;

  @override
  void initState() {
    super.initState();
    _openTime = _normalizeHm(widget.item.openTime) ?? '09:00';
    _closeTime = _normalizeHm(widget.item.closeTime) ?? '15:00';
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
            _ClockTimeField(
              label: 'Opening time',
              value: _openTime,
              onPicked: (hm) => setState(() => _openTime = hm),
            ),
            _ClockTimeField(
              label: 'Closing time',
              value: _closeTime,
              onPicked: (hm) => setState(() => _closeTime = hm),
            ),
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
                      _update(
                        item.copyWith(
                          openTime: _openTime,
                          closeTime: _closeTime,
                          deletionTime: _closeTime,
                          fillTime: _closeTime,
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
        keyboardType: TextInputType.number,
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

class _ClockTimeField extends StatelessWidget {
  const _ClockTimeField({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  final String label;
  final String value;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    final display = _formatDisplay(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _pick(context),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.schedule_outlined),
            border: const OutlineInputBorder(),
          ),
          child: Text(
            display,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final initial = _parseHm(value) ?? const TimeOfDay(hour: 9, minute: 0);
    final picked = await showDialog<TimeOfDay>(
      context: context,
      builder: (context) => _MinimalTimePickerDialog(
        title: label,
        initialTime: initial,
      ),
    );
    if (picked == null) return;
    onPicked(_formatHm(picked));
  }
}

class _MinimalTimePickerDialog extends StatefulWidget {
  const _MinimalTimePickerDialog({
    required this.title,
    required this.initialTime,
  });

  final String title;
  final TimeOfDay initialTime;

  @override
  State<_MinimalTimePickerDialog> createState() =>
      _MinimalTimePickerDialogState();
}

class _MinimalTimePickerDialogState extends State<_MinimalTimePickerDialog> {
  late int _hour12;
  late int _minute;
  late bool _isAm;

  static const _hours = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  static final _minutes = List<int>.generate(60, (i) => i);

  @override
  void initState() {
    super.initState();
    final t = widget.initialTime;
    _hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    _minute = t.minute;
    _isAm = t.period == DayPeriod.am;
  }

  TimeOfDay get _selected {
    var hour24 = _hour12 % 12;
    if (!_isAm) hour24 += 12;
    return TimeOfDay(hour: hour24, minute: _minute);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _LabeledDropdown<int>(
                  label: 'Hour',
                  value: _hour12,
                  items: _hours,
                  itemLabel: (h) => h.toString().padLeft(2, '0'),
                  onChanged: (v) => setState(() => _hour12 = v),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 18, left: 6, right: 6),
                child: Text(
                  ':',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: _LabeledDropdown<int>(
                  label: 'Minute',
                  value: _minute,
                  items: _minutes,
                  itemLabel: (m) => m.toString().padLeft(2, '0'),
                  onChanged: (v) => setState(() => _minute = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(value: true, label: Text('AM')),
              ButtonSegment<bool>(value: false, label: Text('PM')),
            ],
            selected: {_isAm},
            onSelectionChanged: (set) {
              setState(() => _isAm = set.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStateProperty.all(
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDisplay(_formatHm(_selected)),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF667085),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF667085),
          ),
        ),
        const SizedBox(height: 4),
        InputDecorator(
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            border: OutlineInputBorder(),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              isDense: true,
              items: [
                for (final item in items)
                  DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      itemLabel(item),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

TimeOfDay? _parseHm(String raw) {
  final parts = raw.trim().split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String? _normalizeHm(String raw) {
  final time = _parseHm(raw);
  if (time == null) return null;
  return _formatHm(time);
}

String _formatHm(TimeOfDay time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _formatDisplay(String hm) {
  final time = _parseHm(hm);
  if (time == null) return hm;
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
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
