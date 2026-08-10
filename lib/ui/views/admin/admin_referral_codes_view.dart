import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/referral_service.dart';

class AdminReferralCodesView extends StatefulWidget {
  const AdminReferralCodesView({super.key});

  @override
  State<AdminReferralCodesView> createState() => _AdminReferralCodesViewState();
}

class _AdminReferralCodesViewState extends State<AdminReferralCodesView> {
  static const Color _bg = Color(0xFF0B141A);
  static const Color _surface = Color(0xFF111B21);
  static const Color _green = Color(0xFF25D366);
  static const Color _muted = Color(0xFF8696A0);

  final _service = const ReferralService();
  bool _loading = true;
  String? _error;
  List<AdminReferralCodeItem> _codes = [];

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
      final codes = await _service.listCodes();
      if (!mounted) return;
      setState(() {
        _codes = codes;
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

  Future<void> _showCreateDialog() async {
    final codeController = TextEditingController();
    final labelController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _surface,
          title: const Text(
            'Create referral code',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Code (optional)',
                  labelStyle: TextStyle(color: _muted),
                  hintText: 'Auto-generated if empty',
                  hintStyle: TextStyle(color: _muted),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: labelController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Label (optional)',
                  labelStyle: TextStyle(color: _muted),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: _green),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (created != true || !mounted) {
      codeController.dispose();
      labelController.dispose();
      return;
    }

    try {
      final item = await _service.createCode(
        code: codeController.text,
        label: labelController.text,
      );
      if (!mounted) return;
      setState(() {
        _codes = [item, ..._codes];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created ${item.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      codeController.dispose();
      labelController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: const Text('Referral codes'),
        actions: [
          IconButton(
            onPressed: _showCreateDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Create code',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: _green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : RefreshIndicator(
              color: _green,
              onRefresh: _load,
              child: _codes.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        const Center(
                          child: Text(
                            'No referral codes yet',
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
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                      itemCount: _codes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _codes[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2A3942)),
                          ),
                          child: ListTile(
                            title: Text(
                              item.code,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                            subtitle: Text(
                              [
                                if (item.label.isNotEmpty) item.label,
                                '${item.joinedCount} joined',
                                item.isActive ? 'Active' : 'Inactive',
                              ].join(' · '),
                              style: const TextStyle(color: _muted, fontSize: 12),
                            ),
                            trailing: IconButton(
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: item.code),
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Code copied'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy, color: _green),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
