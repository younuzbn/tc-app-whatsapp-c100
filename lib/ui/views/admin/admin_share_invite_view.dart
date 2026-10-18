import 'dart:io';

import 'package:flutter/material.dart';

import '../../../services/android_image_picker.dart';
import '../../../services/share_media_cache.dart';

class AdminShareInviteView extends StatefulWidget {
  const AdminShareInviteView({super.key});

  @override
  State<AdminShareInviteView> createState() => _AdminShareInviteViewState();
}

class _AdminShareInviteViewState extends State<AdminShareInviteView> {
  static const _bg = Color(0xFF07090C);
  static const _card = Color(0xFF171C23);
  static const _muted = Color(0xFF8B95A1);
  static const _cream = Color(0xFFF4F1EA);
  static const _green = Color(0xFF2FCB71);

  final _before = TextEditingController();
  final _after = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  ShareInviteConfig? _config;
  String? _pickedPath;
  String? _pickedKind;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _before.dispose();
    _after.dispose();
    super.dispose();
  }

  void _applyShareText(String raw) {
    final parts = _splitShareText(raw);
    _before.text = parts.before;
    _after.text = parts.after;
  }

  ({String before, String after}) _splitShareText(String raw) {
    var text = raw.trim();
    text = text.replaceAll('{referral}', '{code}');
    final linkAt = text.indexOf('{link}');
    final codeAt = text.indexOf('{code}');
    String clean(String value) => value
        .replaceAll(RegExp(r'`+\s*$'), '')
        .replaceAll(RegExp(r'^`+'), '')
        .trim();
    if (linkAt >= 0 && codeAt > linkAt) {
      return (
        before: text.substring(0, linkAt).trim(),
        after: clean(text.substring(linkAt + 6, codeAt)),
      );
    }
    if (linkAt >= 0) {
      return (
        before: text.substring(0, linkAt).trim(),
        after: clean(text.substring(linkAt + 6).replaceAll('{code}', '')),
      );
    }
    return (before: clean(text.replaceAll('{code}', '')), after: '');
  }

  String _composedShareText() {
    final before = _before.text.trim();
    final after = _after.text.trim();
    return [
      if (before.isNotEmpty) before,
      '{link}',
      if (after.isNotEmpty) after,
      '{code}',
    ].join('\n\n');
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final config = await ShareMediaCache.instance.fetchConfig();
      if (!mounted) return;
      setState(() {
        _config = config;
        _applyShareText(config.shareText);
        _pickedPath = null;
        _pickedKind = null;
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

  Future<void> _pick({required bool video}) async {
    try {
      final path = video
          ? await AndroidImagePicker.pickVideo()
          : await AndroidImagePicker.pickImage();
      if (!mounted || path == null || path.isEmpty) return;
      setState(() {
        _pickedPath = path;
        _pickedKind = video ? 'video' : 'image';
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _card,
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _save() async {
    final text = _composedShareText();
    setState(() => _saving = true);
    try {
      final config = await ShareMediaCache.instance.saveConfig(
        shareText: text,
        mediaPath: _pickedPath,
      );
      if (!mounted) return;
      setState(() {
        _config = config;
        _applyShareText(config.shareText);
        _pickedPath = null;
        _pickedKind = null;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: _card,
          content: Text('Share invite updated. Users will get this next share.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _card,
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Widget _mediaPreview() {
    final picked = _pickedPath;
    if (picked != null) {
      final isImage = _pickedKind != 'video';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isImage ? 'New image selected' : 'New video selected',
            style: const TextStyle(color: _green, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(picked),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            _MediaFileChip(name: picked.split('/').last, kind: 'video'),
        ],
      );
    }
    final config = _config;
    if (config == null || !config.hasMedia) {
      return const Text(
        'No photo or video uploaded yet.',
        style: TextStyle(color: _muted),
      );
    }
    if (config.mediaType == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          config.mediaUrl,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _MediaFileChip(
            name: config.mediaName.isEmpty ? 'Current image' : config.mediaName,
            kind: 'image',
          ),
        ),
      );
    }
    return _MediaFileChip(
      name: config.mediaName.isEmpty ? 'Current video' : config.mediaName,
      kind: 'video',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _cream,
        title: const Text('Share invite'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                const Text(
                  'This text and media are sent when a user taps share on Refer & Earn. Changes apply immediately.',
                  style: TextStyle(color: _muted, height: 1.4),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Share text',
                  style: TextStyle(
                    color: _cream,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                _ShareField(
                  controller: _before,
                  hint: 'Text before the download link',
                  maxLines: 4,
                ),
                const SizedBox(height: 8),
                const _LockedField(label: 'Link'),
                const SizedBox(height: 8),
                _ShareField(
                  controller: _after,
                  hint: 'Text before the invite code',
                  maxLines: 4,
                ),
                const SizedBox(height: 8),
                const _LockedField(label: 'Code'),
                const SizedBox(height: 20),
                const Text(
                  'Share photo or video',
                  style: TextStyle(
                    color: _cream,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2A323C)),
                  ),
                  child: _mediaPreview(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : () => _pick(video: false),
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('Pick image'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _cream,
                          side: const BorderSide(color: Color(0xFF2A323C)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : () => _pick(video: true),
                        icon: const Icon(Icons.videocam_outlined),
                        label: const Text('Pick video'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _cream,
                          side: const BorderSide(color: Color(0xFF2A323C)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _saving ? 'Saving…' : 'Save share invite',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ShareField extends StatelessWidget {
  const _ShareField({
    required this.controller,
    required this.hint,
    this.maxLines = 4,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Color(0xFFF4F1EA)),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF171C23),
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF8B95A1)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2A323C)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2A323C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2FCB71)),
        ),
      ),
    );
  }
}

class _LockedField extends StatelessWidget {
  const _LockedField({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF12161C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2A323C)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2A323C)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, size: 16, color: Color(0xFF8B95A1)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8B95A1),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaFileChip extends StatelessWidget {
  const _MediaFileChip({required this.name, required this.kind});

  final String name;
  final String kind;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          kind == 'video' ? Icons.videocam_rounded : Icons.image_rounded,
          color: const Color(0xFF2FCB71),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(color: Color(0xFFF4F1EA)),
          ),
        ),
      ],
    );
  }
}
