import 'package:flutter/material.dart';

import '../../../services/referral_service.dart';

class AdminReferralTreeView extends StatefulWidget {
  const AdminReferralTreeView({
    super.key,
    this.referralCode,
    this.title,
  });

  /// When null, shows admin root codes. When set, shows users under that code.
  final String? referralCode;
  final String? title;

  @override
  State<AdminReferralTreeView> createState() => _AdminReferralTreeViewState();
}

class _AdminReferralTreeViewState extends State<AdminReferralTreeView> {
  static const Color _bg = Color(0xFF0B141A);
  static const Color _green = Color(0xFF25D366);
  static const Color _muted = Color(0xFF8696A0);

  final _service = const ReferralService();
  bool _loading = true;
  String? _error;
  List<ReferralTreeNode> _roots = [];
  ReferralTreeNode? _node;

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
      if (widget.referralCode == null) {
        final roots = await _service.getTreeRoot();
        if (!mounted) return;
        setState(() {
          _roots = roots;
          _node = null;
          _loading = false;
        });
      } else {
        final node = await _service.getTreeByCode(widget.referralCode!);
        if (!mounted) return;
        setState(() {
          _node = node;
          _roots = [];
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _openCode(String code, {String? title}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminReferralTreeView(
          referralCode: code,
          title: title ?? code,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ??
        (widget.referralCode == null
            ? 'Users hierarchy'
            : widget.referralCode!);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : RefreshIndicator(
              color: _green,
              onRefresh: _load,
              child: _buildBody(),
            ),
    );
  }

  Widget _buildBody() {
    if (_error != null && _roots.isEmpty && _node == null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      );
    }

    if (widget.referralCode == null) {
      if (_roots.isEmpty) {
        return ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text(
                'No admin referral codes yet.\nCreate one from Referral codes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted),
              ),
            ),
          ],
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: _roots.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final root = _roots[index];
          return _CardTile(
            title: root.code,
            subtitle: [
              if (root.label.isNotEmpty) root.label,
              '${root.joinedCount} joined',
            ].join(' · '),
            trailing: '${root.joinedCount}',
            onTap: () => _openCode(
              root.code,
              title: root.label.isNotEmpty
                  ? '${root.code} · ${root.label}'
                  : root.code,
            ),
          );
        },
      );
    }

    final node = _node;
    if (node == null) {
      return const SizedBox.shrink();
    }

    if (node.users.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              node.ownerDisplay == null
                  ? 'No users joined with ${node.code} yet.'
                  : 'No users joined under ${node.ownerDisplay} (${node.code}).',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: node.users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = node.users[index];
        return _CardTile(
          title: user.displayPhoneNumber,
          subtitle: 'Code ${user.referralCode} · ${user.childCount} invited',
          trailing: '${user.childCount}',
          onTap: () => _openCode(
            user.referralCode,
            title: user.displayPhoneNumber,
          ),
        );
      },
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF111B21),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A3942)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8696A0),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D3D2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trailing,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF25D366),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Color(0xFF8696A0)),
            ],
          ),
        ),
      ),
    );
  }
}
