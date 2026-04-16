import 'package:flutter/material.dart';

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

  static final List<String> _resultFields = <String>[
    'firstprice',
    'secondprice',
    'thirdprice',
    'fourthprice',
    'fifthplace',
    ...List<String>.generate(30, (index) => 'field${index + 6}'),
  ];

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
        if (value.isNotEmpty) {
          payload[field] = value;
        }
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

  @override
  Widget build(BuildContext context) {
    final title = widget.editMode ? 'Edit Result' : 'Add Result';
    final dateLabel =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: Text('$title - ${widget.game.name}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
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
                for (final field in _resultFields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: _controllers[field],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: field.toUpperCase(),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving...' : title),
                ),
              ],
            ),
    );
  }
}
