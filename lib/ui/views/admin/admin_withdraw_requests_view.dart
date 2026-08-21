import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/android_image_picker.dart';
import '../../../services/wallet_service.dart';

class AdminWithdrawRequestsView extends StatefulWidget {
  const AdminWithdrawRequestsView({super.key});

  @override
  State<AdminWithdrawRequestsView> createState() =>
      _AdminWithdrawRequestsViewState();
}

class _AdminWithdrawRequestsViewState extends State<AdminWithdrawRequestsView> {
  static const Color _bg = Color(0xFF0B141A);
  static const Color _surface = Color(0xFF111B21);
  static const Color _green = Color(0xFF25D366);
  static const Color _muted = Color(0xFF8696A0);

  final _service = const WalletService();
  bool _loading = true;
  String? _error;
  String _filter = 'all';
  List<WithdrawRequestItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.fetchAdminWithdrawRequests(
        status: _filter == 'all' ? null : _filter,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _act(WithdrawRequestItem item, String action) async {
    final result = await showDialog<_AdminActionResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AdminWithdrawActionDialog(action: action),
    );
    if (result == null || !mounted) return;
    try {
      await _service.updateAdminWithdrawRequest(
        id: item.id,
        action: action,
        note: result.note,
        rejectReason: result.reason,
        imageBase64: result.imageBase64,
        imageMime: result.imageMime,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'reject'
                ? 'Marked as Failed'
                : action == 'complete'
                    ? 'Marked as Processed'
                    : 'Approved',
          ),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _openImage(String url) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullScreenImagePage(imageUrl: url),
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
        title: const Text('Withdraw requests'),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: [
                for (final value in const [
                  'all',
                  'processing',
                  'processed',
                  'failed',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(value[0].toUpperCase() + value.substring(1)),
                      selected: _filter == value,
                      onSelected: (_) {
                        setState(() => _filter = value);
                        _load();
                      },
                      selectedColor: _green,
                      labelStyle: TextStyle(
                        color: _filter == value ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      backgroundColor: _surface,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _green))
                : RefreshIndicator(
                    color: _green,
                    onRefresh: _load,
                    child: _items.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              Text(
                                _error ?? 'No withdraw requests.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: _muted),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                            itemCount: _items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF1F2C34)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.phoneNumber.isNotEmpty
                                                ? item.phoneNumber
                                                : item.username,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: item.statusColor()
                                                .withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            item.displayStatus,
                                            style: TextStyle(
                                              color: item.statusColor(),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '₹${item.amount.toStringAsFixed(item.amount.truncateToDouble() == item.amount ? 0 : 2)}',
                                      style: const TextStyle(
                                        color: _green,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'A/C ${item.accountNumber}',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      'IFSC ${item.ifsc}',
                                      style: const TextStyle(color: _muted),
                                    ),
                                    Text(
                                      'UPI ${item.upiId}',
                                      style: const TextStyle(color: _muted),
                                    ),
                                    if (item.rejectReason.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          'Reason: ${item.rejectReason}',
                                          style: const TextStyle(color: Colors.redAccent),
                                        ),
                                      ),
                                    if (item.adminNote.isNotEmpty &&
                                        item.adminNote != item.rejectReason)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          'Note: ${item.adminNote}',
                                          style: const TextStyle(color: _muted),
                                        ),
                                      ),
                                    if (item.receiptUrl.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      _ProofThumb(
                                        label: 'Payment receipt',
                                        url: item.receiptUrl,
                                        onTap: () => _openImage(item.receiptUrl),
                                      ),
                                    ],
                                    if (item.rejectImageUrl.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      _ProofThumb(
                                        label: 'Reject proof',
                                        url: item.rejectImageUrl,
                                        onTap: () => _openImage(item.rejectImageUrl),
                                      ),
                                    ],
                                    if (item.status == 'pending' ||
                                        item.status == 'approved') ...[
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          if (item.status == 'pending')
                                            FilledButton(
                                              onPressed: () => _act(item, 'accept'),
                                              style: FilledButton.styleFrom(
                                                backgroundColor: _green,
                                                foregroundColor: Colors.black,
                                              ),
                                              child: const Text('Approve'),
                                            ),
                                          if (item.status == 'approved')
                                            FilledButton(
                                              onPressed: () => _act(item, 'complete'),
                                              style: FilledButton.styleFrom(
                                                backgroundColor: const Color(0xFF60A5FA),
                                              ),
                                              child: const Text('Mark processed'),
                                            ),
                                          OutlinedButton(
                                            onPressed: () => _act(item, 'reject'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.redAccent,
                                              side: const BorderSide(
                                                color: Colors.redAccent,
                                              ),
                                            ),
                                            child: const Text('Reject'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
          if (_error != null && _items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ),
        ],
      ),
    );
  }
}

class _AdminActionResult {
  const _AdminActionResult({
    required this.note,
    required this.reason,
    this.imageBase64,
    this.imageMime = 'image/jpeg',
  });

  final String note;
  final String reason;
  final String? imageBase64;
  final String imageMime;
}

class _AdminWithdrawActionDialog extends StatefulWidget {
  const _AdminWithdrawActionDialog({required this.action});

  final String action;

  @override
  State<_AdminWithdrawActionDialog> createState() =>
      _AdminWithdrawActionDialogState();
}

class _AdminWithdrawActionDialogState extends State<_AdminWithdrawActionDialog> {
  final _note = TextEditingController();
  File? _imageFile;
  String? _error;
  bool _picking = false;

  bool get _isReject => widget.action == 'reject';
  bool get _isApprove => widget.action == 'accept';

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final path = await AndroidImagePicker.pickImage();
      if (!mounted) return;
      if (path == null) {
        setState(() => _picking = false);
        return;
      }
      setState(() {
        _imageFile = File(path);
        _picking = false;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _picking = false;
        _error = e.message?.isNotEmpty == true ? e.message : 'Could not open gallery.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _picking = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _submit() async {
    final text = _note.text.trim();
    if (_isReject && text.length < 4) {
      setState(() => _error = 'Enter a reason for rejecting this request.');
      return;
    }

    String? imageBase64;
    var mime = 'image/jpeg';
    if (_imageFile != null) {
      final bytes = await _imageFile!.readAsBytes();
      imageBase64 = base64Encode(bytes);
      final path = _imageFile!.path.toLowerCase();
      mime = path.endsWith('.png')
          ? 'image/png'
          : path.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';
    }
    if (!mounted) return;
    Navigator.pop(
      context,
      _AdminActionResult(
        note: _isReject ? '' : text,
        reason: _isReject ? text : '',
        imageBase64: imageBase64,
        imageMime: mime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isReject
        ? 'Reject request'
        : _isApprove
            ? 'Approve request'
            : 'Mark processed';
    final imageLabel = _isReject ? 'Optional proof image' : 'Payment receipt (optional)';
    return AlertDialog(
      backgroundColor: const Color(0xFF111B21),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _note,
              maxLines: _isReject ? 3 : 2,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: _isReject ? 'Reason (required)' : 'Note (optional)',
                labelStyle: const TextStyle(color: Color(0xFF8696A0)),
              ),
            ),
            const SizedBox(height: 14),
            Text(imageLabel, style: const TextStyle(color: Color(0xFF8696A0), fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                InkWell(
                  onTap: _picking ? null : _pickImage,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B141A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2A3942)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _picking
                        ? const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF25D366),
                              ),
                            ),
                          )
                        : _imageFile != null
                            ? Image.file(_imageFile!, fit: BoxFit.cover)
                            : const Icon(Icons.image_outlined, color: Color(0xFF8696A0)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _picking ? null : _pickImage,
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: Text(_imageFile == null ? 'Upload image' : 'Change image'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(color: Color(0xFF2A3942)),
                    ),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _picking ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: _isReject ? Colors.redAccent : const Color(0xFF25D366),
          ),
          child: Text(_isReject
              ? 'Reject'
              : _isApprove
                  ? 'Approve'
                  : 'Mark processed'),
        ),
      ],
    );
  }
}

class _ProofThumb extends StatelessWidget {
  const _ProofThumb({
    required this.label,
    required this.url,
    required this.onTap,
  });

  final String label;
  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 56,
                height: 56,
                color: const Color(0xFF1F2C34),
                child: const Icon(Icons.image_not_supported, color: Color(0xFF8696A0)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Color(0xFF8696A0))),
        ],
      ),
    );
  }
}

class _FullScreenImagePage extends StatelessWidget {
  const _FullScreenImagePage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Text(
                      'Unable to load image',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
