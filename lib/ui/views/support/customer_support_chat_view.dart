import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/android_image_picker.dart';
import '../../../services/support_service.dart';
import '../../theme/win_theme.dart';

class CustomerSupportChatView extends StatefulWidget {
  const CustomerSupportChatView({super.key});

  @override
  State<CustomerSupportChatView> createState() =>
      _CustomerSupportChatViewState();
}

class _CustomerSupportChatViewState extends State<CustomerSupportChatView> {
  static const _bgAsset = 'assets/wallet_bg.jpeg';
  final _supportService = const SupportService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  bool _loading = true;
  bool _sending = false;
  String? _error;
  List<ComplaintMessageItem> _messages = [];

  String? _selectedMediaPath;
  String? _selectedMediaType; // 'image' or 'video'

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadMessages(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final messages = await _supportService.fetchUserMessages();
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
      if (!silent) {
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickAttachment(String type) async {
    try {
      String? path;
      if (type == 'image') {
        path = await AndroidImagePicker.pickImage();
      } else if (type == 'video') {
        path = await AndroidImagePicker.pickVideo();
      }
      if (!mounted || path == null || path.isEmpty) return;
      setState(() {
        _selectedMediaPath = path;
        _selectedMediaType = type;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to pick file')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
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
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Attach Media',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _AttachmentOption(
                      icon: Icons.image_rounded,
                      color: const Color(0xFF3B82F6),
                      label: 'Photo / Image',
                      onTap: () {
                        Navigator.pop(context);
                        _pickAttachment('image');
                      },
                    ),
                    _AttachmentOption(
                      icon: Icons.videocam_rounded,
                      color: const Color(0xFFEC4899),
                      label: 'Video',
                      onTap: () {
                        Navigator.pop(context);
                        _pickAttachment('video');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    final mediaPath = _selectedMediaPath;
    final mediaType = _selectedMediaType;

    if (text.isEmpty && mediaPath == null) return;
    if (_sending) return;

    setState(() => _sending = true);
    _textController.clear();
    setState(() {
      _selectedMediaPath = null;
      _selectedMediaType = null;
    });

    try {
      await _supportService.sendUserMessage(
        text: text,
        mediaPath: mediaPath,
        mediaType: mediaType,
      );
      await _loadMessages(silent: true);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to send message: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
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
        PageRouteBuilder<void>(
          opaque: false,
          barrierColor: Colors.black,
          pageBuilder: (context, animation, secondaryAnimation) {
            return _SupportImagePage(imageUrl: url);
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WinStatusBar(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: WinTheme.bg),
            const DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(_bgAsset),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _SupportAppBar(
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: WinTheme.green,
                            ),
                          )
                        : _error != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                            : _messages.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          Icons.support_agent_rounded,
                                          size: 56,
                                          color: WinTheme.muted,
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Customer Support & Complaints',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'Send any query, concern, image or video.\nOur admin support will respond shortly.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: WinTheme.muted,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 16,
                                    ),
                                    itemCount: _messages.length,
                                    itemBuilder: (context, index) {
                                      final msg = _messages[index];
                                      return _ChatBubble(
                                        message: msg,
                                        onTapMedia: () => _openMedia(msg),
                                      );
                                    },
                                  ),
                  ),
                  if (_selectedMediaPath != null)
                    _AttachmentPreviewBar(
                      path: _selectedMediaPath!,
                      type: _selectedMediaType ?? 'image',
                      onRemove: () {
                        setState(() {
                          _selectedMediaPath = null;
                          _selectedMediaType = null;
                        });
                      },
                    ),
                  _InputBar(
                    controller: _textController,
                    sending: _sending,
                    onAttach: _showAttachmentMenu,
                    onSend: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportImagePage extends StatelessWidget {
  const _SupportImagePage({required this.imageUrl});

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
                minScale: 0.8,
                maxScale: 4,
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
    );
  }
}

class _SupportAppBar extends StatelessWidget {
  const _SupportAppBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xAA101820),
        border: Border(bottom: BorderSide(color: Color(0x334ADE80))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const CircleAvatar(
            radius: 20,
            backgroundColor: WinTheme.green,
            child: Icon(
              Icons.support_agent_rounded,
              color: Colors.black,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Customer Support & Complaints',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Online • Official Support',
                  style: TextStyle(
                    color: WinTheme.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.onTapMedia,
  });

  final ComplaintMessageItem message;
  final VoidCallback onTapMedia;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isFromUser;
    final timeStr =
        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xDD16A34A) : const Color(0xDD1E293B),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser ? const Color(0x664ADE80) : const Color(0x44FFFFFF),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isUser) ...[
              const Text(
                'Support Admin',
                style: TextStyle(
                  color: WinTheme.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (message.hasMedia) ...[
              GestureDetector(
                onTap: onTapMedia,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: message.mediaType == 'image'
                        ? Image.network(
                            message.mediaUrl,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 120,
                              color: Colors.black45,
                              child: const Center(
                                child: Icon(Icons.broken_image, color: Colors.white),
                              ),
                            ),
                          )
                        : Container(
                            height: 160,
                            width: double.infinity,
                            color: Colors.black87,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.play_circle_fill_rounded,
                                  size: 48,
                                  color: WinTheme.green,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Tap to view / play video',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                  ),
                ),
                if (isUser) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.readByAdmin
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 14,
                    color: message.readByAdmin
                        ? Colors.lightBlueAccent
                        : Colors.white60,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentPreviewBar extends StatelessWidget {
  const _AttachmentPreviewBar({
    required this.path,
    required this.type,
    required this.onRemove,
  });

  final String path;
  final String type;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: const Color(0xFF1E293B),
      child: Row(
        children: [
          Icon(
            type == 'video' ? Icons.videocam_rounded : Icons.image_rounded,
            color: WinTheme.green,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Attached ${type.toUpperCase()}: ${path.split('/').last}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onAttach,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onAttach;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      color: const Color(0xEE0F172A),
      child: Row(
        children: [
          IconButton(
            onPressed: sending ? null : onAttach,
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: WinTheme.green,
              size: 26,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !sending,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              cursorColor: WinTheme.green,
              decoration: const InputDecoration(
                hintText: 'Type your message or complaint…',
                hintStyle: TextStyle(color: WinTheme.muted, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: sending ? null : onSend,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
                  ),
                ),
                child: Center(
                  child: sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.black,
                          size: 20,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  const _AttachmentOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
