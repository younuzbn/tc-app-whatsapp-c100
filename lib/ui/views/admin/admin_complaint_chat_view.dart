import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/android_image_picker.dart';
import '../../../services/support_service.dart';
import '../../theme/win_theme.dart';

class AdminComplaintChatView extends StatefulWidget {
  const AdminComplaintChatView({
    super.key,
    required this.userId,
    required this.userName,
    required this.userPhone,
  });

  final String userId;
  final String userName;
  final String userPhone;

  @override
  State<AdminComplaintChatView> createState() => _AdminComplaintChatViewState();
}

class _AdminComplaintChatViewState extends State<AdminComplaintChatView> {
  final _service = const SupportService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  bool _loading = true;
  bool _sending = false;
  String? _error;
  List<ComplaintMessageItem> _messages = [];
  String? _selectedMediaPath;
  String? _selectedMediaType;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(_load(silent: true));
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final messages = await _service.fetchAdminUserMessages(widget.userId);
      if (!mounted) return;
      final grew = messages.length != _messages.length;
      setState(() {
        _messages = messages;
        _loading = false;
      });
      if (!silent || grew) _scrollToBottom();
    } catch (error) {
      if (!mounted || silent) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _pickAttachment(String type) async {
    try {
      final path = type == 'video'
          ? await AndroidImagePicker.pickVideo()
          : await AndroidImagePicker.pickImage();
      if (!mounted || path == null || path.isEmpty) return;
      setState(() {
        _selectedMediaPath = path;
        _selectedMediaType = type;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  void _showAttachmentMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    unawaited(_pickAttachment('image'));
                  },
                  icon: const Icon(Icons.image_rounded, color: WinTheme.green),
                  label: const Text('Photo', style: TextStyle(color: Colors.white)),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    unawaited(_pickAttachment('video'));
                  },
                  icon: const Icon(Icons.videocam_rounded, color: WinTheme.green),
                  label: const Text('Video', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    final mediaPath = _selectedMediaPath;
    final mediaType = _selectedMediaType;
    if ((text.isEmpty && mediaPath == null) || _sending) return;

    setState(() {
      _sending = true;
      _selectedMediaPath = null;
      _selectedMediaType = null;
    });
    _textController.clear();
    try {
      await _service.sendAdminMessage(
        userId: widget.userId,
        text: text,
        mediaPath: mediaPath,
        mediaType: mediaType,
      );
      await _load(silent: true);
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openMedia(ComplaintMessageItem message) async {
    final url = message.mediaUrl;
    if (url.isEmpty) return;
    if (message.mediaType == 'image') {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4,
                      child: Center(
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Text(
                            'Unable to load image',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.userName.trim().isNotEmpty
        ? widget.userName
        : widget.userPhone;
    return Scaffold(
      backgroundColor: const Color(0xFF0B141A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B141A),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            Text(
              widget.userPhone,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8696A0)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: WinTheme.green),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final mine = message.isFromAdmin;
                          return Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                              ),
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                              decoration: BoxDecoration(
                                color: mine
                                    ? const Color(0xDD16A34A)
                                    : const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (message.hasMedia)
                                    GestureDetector(
                                      onTap: () => _openMedia(message),
                                      child: message.mediaType == 'image'
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.network(
                                                message.mediaUrl,
                                                height: 160,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : const Row(
                                              children: [
                                                Icon(
                                                  Icons.play_circle_fill_rounded,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Play video',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  if (message.text.isNotEmpty) ...[
                                    if (message.hasMedia) const SizedBox(height: 6),
                                    Text(
                                      message.text,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          if (_selectedMediaPath != null)
            Container(
              color: const Color(0xFF1E293B),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _selectedMediaType == 'video'
                        ? Icons.videocam_rounded
                        : Icons.image_rounded,
                    color: WinTheme.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedMediaPath!.split(Platform.pathSeparator).last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedMediaPath = null;
                        _selectedMediaType = null;
                      });
                    },
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Container(
              color: const Color(0xFF111B21),
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _sending ? null : _showAttachmentMenu,
                    icon: const Icon(Icons.add_circle_outline, color: WinTheme.green),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      enabled: !_sending,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Reply with text, image, or video',
                        hintStyle: TextStyle(color: Color(0xFF8696A0)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded, color: WinTheme.green),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
