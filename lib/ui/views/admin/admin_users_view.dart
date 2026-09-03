import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../../theme/win_theme.dart';

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  static const Color _bg = Color(0xFF0B141A);
  static const Color _surface = Color(0xFF111B21);
  static const Color _green = Color(0xFF25D366);
  static const Color _muted = Color(0xFF8696A0);

  final _service = const AdminService();
  final _search = TextEditingController();
  bool _loading = true;
  bool _busyId = false;
  String? _error;
  List<AdminMobileUser> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await _service.listMobileUsers(query: _search.text);
      if (!mounted) return;
      setState(() {
        _users = users;
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

  Future<void> _toggleBlock(AdminMobileUser user) async {
    final blocking = !user.isBlocked;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title: Text(
          blocking ? 'Block user?' : 'Unblock user?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          blocking
              ? '${user.displayPhoneNumber} will not be able to login, play, add money, or withdraw.'
              : '${user.displayPhoneNumber} will be able to use the app again.',
          style: const TextStyle(color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: blocking ? Colors.orangeAccent : _green,
              foregroundColor: Colors.black,
            ),
            child: Text(blocking ? 'Block' : 'Unblock'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busyId = true);
    try {
      await _service.setMobileUserBlocked(id: user.id, blocked: blocking);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(blocking ? 'User blocked' : 'User unblocked')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busyId = false);
    }
  }

  Future<void> _delete(AdminMobileUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title: const Text(
          'Delete account?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This permanently deletes ${user.displayPhoneNumber}, including sales, wallet, deposits, withdrawals, and notifications. They can register again as a new user.',
          style: const TextStyle(color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busyId = true);
    try {
      await _service.deleteMobileUser(user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busyId = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: const Text('Users'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Search phone, name, or code',
                hintStyle: const TextStyle(color: _muted),
                prefixIcon: const Icon(Icons.search, color: _muted),
                suffixIcon: IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.arrow_forward, color: _green),
                ),
                filled: true,
                fillColor: _surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _green))
                : RefreshIndicator(
                    color: _green,
                    onRefresh: _load,
                    child: _users.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              Center(
                                child: Text(
                                  _error ?? 'No users found',
                                  style: const TextStyle(color: _muted),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: _users.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF2A3942)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.name.isEmpty
                                                    ? user.displayPhoneNumber
                                                    : user.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                user.displayPhoneNumber,
                                                style: const TextStyle(
                                                  color: _muted,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: user.isBlocked
                                                ? const Color(0xFF3A1D1D)
                                                : const Color(0xFF16351F),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            user.isBlocked ? 'Blocked' : 'Active',
                                            style: TextStyle(
                                              color: user.isBlocked
                                                  ? Colors.redAccent
                                                  : _green,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Code ${user.referralCode.isEmpty ? '—' : user.referralCode}  ·  Wallet ₹${WinTheme.rupee(user.total)}',
                                      style: const TextStyle(
                                        color: _muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'Deposit ₹${WinTheme.rupee(user.deposit)}  ·  Winning ₹${WinTheme.rupee(user.winningsBalance)}',
                                      style: const TextStyle(
                                        color: _muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'Withdrawable referral ₹${WinTheme.rupee(user.withdrawableReferral)}  ·  Non withdrawable ₹${WinTheme.rupee(user.nonWithdrawableReferral)}',
                                      style: const TextStyle(
                                        color: _muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: _busyId
                                                ? null
                                                : () => _toggleBlock(user),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: user.isBlocked
                                                  ? _green
                                                  : Colors.orangeAccent,
                                              side: BorderSide(
                                                color: user.isBlocked
                                                    ? _green
                                                    : Colors.orangeAccent,
                                              ),
                                            ),
                                            child: Text(
                                              user.isBlocked ? 'Unblock' : 'Block',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: FilledButton(
                                            onPressed: _busyId
                                                ? null
                                                : () => _delete(user),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
          if (_error != null && _users.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
