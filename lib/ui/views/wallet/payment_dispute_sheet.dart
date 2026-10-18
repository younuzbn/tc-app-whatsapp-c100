import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../services/android_image_picker.dart';
import '../../../services/wallet_service.dart';
import '../../theme/win_theme.dart';

class PaymentDisputeSheet extends StatefulWidget {
  const PaymentDisputeSheet({
    super.key,
    required this.topupId,
    required this.amount,
    required this.statusLabel,
  });

  final String topupId;
  final double amount;
  final String statusLabel;

  @override
  State<PaymentDisputeSheet> createState() => _PaymentDisputeSheetState();
}

class _PaymentDisputeSheetState extends State<PaymentDisputeSheet> {
  static const _reasons = <(String, String)>[
    ('debited_not_credited', 'Money debited but not credited in wallet'),
    ('debited_shows_cancelled', 'Money debited but shows cancelled'),
    ('debited_shows_failed', 'Money debited but showing failed'),
    ('debited_still_processing', 'Money debited but still processing'),
    ('charged_twice', 'Charged more than once'),
    ('other', 'Other'),
  ];

  final _wallet = const WalletService();
  final _noteController = TextEditingController();
  String _reason = 'debited_not_credited';
  final List<String> _images = [];
  bool _sending = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _addImage() async {
    if (_images.length >= 3 || _sending) return;
    final path = await AndroidImagePicker.pickImage();
    if (path == null || !mounted) return;
    setState(() => _images.add(path));
  }

  Future<void> _submit() async {
    if (_sending) return;
    final note = _noteController.text.trim();
    if (_reason == 'other' && note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Describe the issue')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final images = <({String base64, String mime})>[];
      for (final path in _images) {
        final file = File(path);
        if (!await file.exists()) continue;
        final bytes = await file.readAsBytes();
        final lower = path.toLowerCase();
        final mime = lower.endsWith('.png')
            ? 'image/png'
            : lower.endsWith('.webp')
            ? 'image/webp'
            : 'image/jpeg';
        images.add((base64: base64Encode(bytes), mime: mime));
      }
      await _wallet.reportPaymentDispute(
        topupId: widget.topupId,
        reason: _reason,
        note: note,
        images: images,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: WinTheme.green,
        foregroundColor: Colors.white,
        title: const Text('Report payment issue'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            '₹${widget.amount.toStringAsFixed(0)} · ${widget.statusLabel}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tell us what happened. Screenshots are optional.',
            style: TextStyle(color: Color(0xFF666666)),
          ),
          const SizedBox(height: 16),
          ..._reasons.map((item) {
            final selected = _reason == item.$1;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? WinTheme.green : const Color(0xFF9CA3AF),
              ),
              title: Text(item.$2, style: const TextStyle(fontSize: 14)),
              onTap: _sending ? null : () => setState(() => _reason = item.$1),
            );
          }),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLength: 500,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: _reason == 'other' ? 'Describe the issue' : 'Note (optional)',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._images.map(
                (path) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(path),
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: _sending
                            ? null
                            : () => setState(() => _images.remove(path)),
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_images.length < 3)
                OutlinedButton.icon(
                  onPressed: _sending ? null : _addImage,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Add image'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _sending ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: WinTheme.green,
                foregroundColor: Colors.white,
              ),
              child: Text(_sending ? 'Sending…' : 'Send report'),
            ),
          ),
        ],
      ),
    );
  }
}
