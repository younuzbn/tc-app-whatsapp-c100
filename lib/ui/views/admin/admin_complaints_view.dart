import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/support_service.dart';
import 'admin_complaint_chat_view.dart';

class AdminComplaintsView extends StatefulWidget {
  const AdminComplaintsView({super.key});

  @override
  State<AdminComplaintsView> createState() => _AdminComplaintsViewState();
}

class _AdminComplaintsViewState extends State<AdminComplaintsView> {
  static const Color _bg = Color(0xFF0B141A);
  static const Color _surface = Color(0xFF111B21);
  static const Color _green = Color(0xFF25D366);
  static const Color _muted = Color(0xFF8696A0);

  final _service = const SupportService();
  Timer? _pollTimer;
  bool _loading = true;
  String? _error;
  List<ComplaintThreadItem> _threads = [];

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      unawaited(_load(silent: true));
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
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
      final threads = await _service.fetchAdminThreads();
      if (!mounted) return;
      setState(() {
        _threads = threads;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (!silent) {
          _error = error.toString().replaceFirst('Exception: ', '');
        }
        _loading = false;
      });
    }
  }

  String _preview(ComplaintThreadItem item) {
    if (item.lastMessage.trim().isNotEmpty) return item.lastMessage.trim();
    if (item.lastMediaType == 'image') return 'Photo';
    if (item.lastMediaType == 'video') return 'Video';
    return 'No message';
  }

  String _timeLabel(DateTime time) {
    final local = time.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _openThread(ComplaintThreadItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminComplaintChatView(
          userId: item.userId,
          userName: item.userName,
          userPhone: item.userPhone,
        ),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: const Text('Complaints'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : RefreshIndicator(
              color: _green,
              onRefresh: _load,
              child: _threads.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        const Center(
                          child: Text(
                            'No complaints yet',
                            style: TextStyle(color: _muted),
                          ),
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                      itemCount: _threads.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _threads[index];
                        final title = item.userName.trim().isNotEmpty
                            ? item.userName
                            : item.userPhone;
                        return Material(
                          color: _surface,
                          borderRadius: BorderRadius.circular(12),
                          child: ListTile(
                            onTap: () => _openThread(item),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFF2A3942)),
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${item.userPhone} · ${_preview(item)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: _muted, fontSize: 12),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _timeLabel(item.lastMessageTime),
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 11,
                                  ),
                                ),
                                if (item.unreadCount > 0) ...[
                                  const SizedBox(height: 6),
                                  CircleAvatar(
                                    radius: 11,
                                    backgroundColor: _green,
                                    child: Text(
                                      item.unreadCount > 99
                                          ? '99+'
                                          : '${item.unreadCount}',
                                      style: const TextStyle(
                                        color: Color(0xFF052E16),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
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
    );
  }
}
