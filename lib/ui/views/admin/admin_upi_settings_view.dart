import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/admin_service.dart';
import '../../../services/android_image_picker.dart';

class AdminUpiSettingsView extends StatefulWidget {
  const AdminUpiSettingsView({super.key});

  @override
  State<AdminUpiSettingsView> createState() => _AdminUpiSettingsViewState();
}

class _AdminUpiSettingsViewState extends State<AdminUpiSettingsView> {
  static const Color _bg = Color(0xFF0B141A);
  static const Color _surface = Color(0xFF111B21);
  static const Color _green = Color(0xFF25D366);
  static const Color _muted = Color(0xFF8696A0);

  final _service = const AdminService();
  final _upiId = TextEditingController();
  UpiPaymentConfig _config = const UpiPaymentConfig();
  String? _pickedPath;
  bool _loading = true;
  bool _saving = false;
  String? _message;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _message = null;
      _error = false;
    });
    try {
      final config = await _service.getUpiSettings();
      _config = config;
      _upiId.text = config.upiId;
      _pickedPath = null;
    } catch (e) {
      _error = true;
      _message = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickQr() async {
    try {
      final path = await AndroidImagePicker.pickImage();
      if (!mounted || path == null || path.isEmpty) return;
      setState(() {
        _pickedPath = path;
        _message = null;
        _error = false;
      });
    } on PlatformException catch (e) {
      setState(() {
        _error = true;
        _message = e.message ?? 'Could not open gallery';
      });
    }
  }

  Future<void> _save() async {
    final upiId = _upiId.text.trim();
    if (upiId.isEmpty || !upiId.contains('@')) {
      setState(() {
        _error = true;
        _message = 'Enter a valid UPI ID, for example name@okaxis';
      });
      return;
    }
    setState(() {
      _saving = true;
      _message = null;
      _error = false;
    });
    try {
      String? qrBase64;
      String? qrMime;
      final picked = _pickedPath;
      if (picked != null && picked.isNotEmpty) {
        final bytes = await File(picked).readAsBytes();
        qrBase64 = base64Encode(bytes);
        final lower = picked.toLowerCase();
        qrMime = lower.endsWith('.png')
            ? 'image/png'
            : lower.endsWith('.webp')
                ? 'image/webp'
                : 'image/jpeg';
      }
      await _service.updateUpiSettings(
        UpiPaymentConfig(upiId: upiId, qrImageUrl: _config.qrImageUrl),
        qrImageBase64: qrBase64,
        qrImageMime: qrMime,
      );
      await _load();
      if (!mounted) return;
      setState(() {
        _message = 'UPI details saved.';
        _error = false;
      });
    } catch (e) {
      _error = true;
      _message = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _upiId.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: _muted),
      hintStyle: const TextStyle(color: Color(0xFF667781)),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF2A3942)),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: _green),
      ),
    );
  }

  Widget _qrPreview() {
    final picked = _pickedPath;
    if (picked != null) {
      return Image.file(File(picked), fit: BoxFit.contain);
    }
    if (_config.hasQr) {
      return Image.network(_config.qrNetworkUrl, fit: BoxFit.contain);
    }
    return const Center(
      child: Text(
        'No QR uploaded yet',
        style: TextStyle(color: _muted),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: const Text('UPI payment'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                const Text(
                  'Users copy this UPI ID or download the QR, pay from their UPI app, then upload the payment screenshot.',
                  style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _upiId,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: _decoration(
                          'UPI ID',
                          hint: 'yourname@okaxis',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'QR code',
                  style: TextStyle(color: _muted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2A3942)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _qrPreview(),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _pickQr,
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: Text(_pickedPath == null && !_config.hasQr
                      ? 'Upload QR image'
                      : 'Change QR image'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _green,
                    side: const BorderSide(color: Color(0xFF2A3942)),
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _message!,
                    style: TextStyle(
                      color: _error ? Colors.redAccent : _green,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(_saving ? 'Saving...' : 'Save UPI details'),
                ),
              ],
            ),
    );
  }
}
