import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/result_service.dart';
import '../home/game_chat_data.dart';

class AdminResultEditorView extends StatefulWidget {
  const AdminResultEditorView({
    super.key,
    required this.game,
    required this.editMode,
  });

  final GameChatData game;
  final bool editMode;

  @override
  State<AdminResultEditorView> createState() => _AdminResultEditorViewState();
}

class _AdminResultEditorViewState extends State<AdminResultEditorView> {
  final _service = const ResultService();
  final _controllers = <String, TextEditingController>{};
  DateTime _selectedDate = DateTime.now();
  String? _resultId;
  bool _loading = false;
  bool _saving = false;
  String? _message;

  static const List<String> _topFields = <String>[
    'firstprice',
    'secondprice',
    'thirdprice',
    'fourthprice',
    'fifthplace',
  ];

  static final List<String> _bottomFields = List<String>.generate(
    30,
    (index) => 'field${index + 6}',
  );

  static final List<String> _resultFields = <String>[
    ..._topFields,
    ..._bottomFields,
  ];

  @override
  void initState() {
    super.initState();
    for (final field in _resultFields) {
      _controllers[field] = TextEditingController();
    }
    if (widget.editMode) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final existing = await _service.getResultForDate(
        timeSlot: widget.game.timeSlot,
        date: _selectedDate,
      );
      _resultId = existing?.id;
      for (final field in _resultFields) {
        _controllers[field]!.text = existing?.fields[field] ?? '';
      }
      _message = existing == null ? 'No result found for selected date.' : null;
    } catch (error) {
      _message = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final payload = <String, String>{};
      for (final field in _resultFields) {
        final value = _controllers[field]!.text.trim();
        if (value.length != 3 || int.tryParse(value) == null) {
          throw Exception('Fill every field with exactly 3 digits before saving.');
        }
        payload[field] = value;
      }

      if (widget.editMode) {
        if (_resultId == null || _resultId!.isEmpty) {
          throw Exception('No existing result found to edit for this date.');
        }
        await _service.updateResult(
          id: _resultId!,
          date: _selectedDate,
          fields: payload,
        );
      } else {
        await _service.createResult(
          timeSlot: widget.game.timeSlot,
          date: _selectedDate,
          fields: payload,
        );
      }

      _message = widget.editMode
          ? 'Result updated and broadcast sent.'
          : 'Result added and broadcast sent.';

      if (widget.editMode) {
        await _loadExisting();
      }
    } catch (error) {
      _message = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _resultId = null;
    });
    if (widget.editMode) {
      await _loadExisting();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _fieldCell(String field) {
    return TextField(
      controller: _controllers[field],
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 3,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      decoration: const InputDecoration(
        isDense: true,
        counterText: '',
        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _fiveRow(List<String> fields) {
    return Row(
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(child: _fieldCell(fields[i])),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.editMode ? 'Edit Result' : 'Add Result';
    final dateLabel =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    final bottomRows = <List<String>>[];
    for (var i = 0; i < _bottomFields.length; i += 5) {
      bottomRows.add(_bottomFields.sublist(i, i + 5));
    }

    return Scaffold(
      appBar: AppBar(title: Text('$title - ${widget.game.name}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Date: $dateLabel',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _pickDate,
                      child: const Text('Change Date'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_message != null) ...[
                  Text(_message!, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 10),
                ],
                _fiveRow(_topFields),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(thickness: 1.2, height: 1),
                ),
                for (var i = 0; i < bottomRows.length; i++) ...[
                  if (i > 0) const SizedBox(height: 6),
                  _fiveRow(bottomRows[i]),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving...' : title),
                ),
              ],
            ),
    );
  }
}
