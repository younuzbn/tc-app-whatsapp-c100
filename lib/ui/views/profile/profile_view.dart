import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/android_image_picker.dart';
import '../../../services/auth_service.dart';
import '../../../services/session_service.dart';
import '../../theme/win_theme.dart';
import '../auth/phone_login/phone_login_view.dart';
import '../wallet/wallet_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _auth = const AuthService();
  bool _loading = true;
  bool _uploadingPhoto = false;
  String? _error;
  MobileProfile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final profile = await _auth.fetchProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
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

  Future<void> _pickProfileImage() async {
    if (_uploadingPhoto) return;
    try {
      final path = await AndroidImagePicker.pickImage();
      if (!mounted || path == null || path.isEmpty) return;
      setState(() {
        _uploadingPhoto = true;
        _error = null;
      });
      final file = File(path);
      final bytes = await file.readAsBytes();
      final lower = path.toLowerCase();
      final mime = lower.endsWith('.png')
          ? 'image/png'
          : lower.endsWith('.webp')
          ? 'image/webp'
          : 'image/jpeg';
      await _auth.updateProfile(
        imageBase64: base64Encode(bytes),
        imageMime: mime,
      );
      await _load(showSpinner: false);
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message?.isNotEmpty == true
            ? e.message
            : 'Could not open gallery. Please reinstall the latest APK.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _profile?.name ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: WinTheme.surface,
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Your name',
            labelStyle: TextStyle(color: WinTheme.muted),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: WinTheme.green),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null) return;
    try {
      await _auth.updateProfile(name: name);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final displayName = (profile?.name.trim().isNotEmpty == true)
        ? profile!.name.trim()
        : 'Your name';
    final letter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'N';
    final phone = profile?.displayPhoneNumber ??
        SessionService.displayPhoneNumber ??
        '';

    return Scaffold(
      backgroundColor: WinTheme.bg,
      appBar: AppBar(
        backgroundColor: WinTheme.bg,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !widget.embedded,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: WinTheme.green))
          : RefreshIndicator(
              color: WinTheme.green,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                    ),
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickProfileImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 42,
                                backgroundColor: WinTheme.green,
                                backgroundImage:
                                    profile?.profileImageUrl != null &&
                                        profile!.profileImageUrl!.isNotEmpty
                                    ? NetworkImage(profile.profileImageUrl!)
                                    : null,
                                child:
                                    profile?.profileImageUrl != null &&
                                        profile!.profileImageUrl!.isNotEmpty
                                    ? null
                                    : Text(
                                        letter,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 36,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: WinTheme.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: _uploadingPhoto
                                      ? const Padding(
                                          padding: EdgeInsets.all(6),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.black,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt_rounded,
                                          size: 15,
                                          color: Colors.black,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(phone, style: const TextStyle(color: WinTheme.muted)),
                        const SizedBox(height: 4),
                        Text(
                          profile?.memberSince == null
                              ? 'Member since —'
                              : 'Member since ${WinTheme.monthDay(profile!.memberSince)}',
                          style: const TextStyle(color: WinTheme.muted, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: WinTheme.greenSoft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text.rich(
                            TextSpan(
                              text: 'Referral Code ',
                              style: const TextStyle(color: Colors.white70),
                              children: [
                                TextSpan(
                                  text: profile?.referralCode ?? SessionService.referralCode ?? '—',
                                  style: const TextStyle(
                                    color: WinTheme.green,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: profile?.isActive == false
                                    ? Colors.redAccent
                                    : WinTheme.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              profile?.isActive == false ? 'Account Inactive' : 'Account Active',
                              style: TextStyle(
                                color: profile?.isActive == false
                                    ? Colors.redAccent
                                    : WinTheme.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: WinTheme.card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _StatCell(
                          value: '₹${WinTheme.rupee(profile?.entryBalance ?? 0)}',
                          label: 'Entry Balance',
                          color: WinTheme.green,
                        ),
                        _StatCell(
                          value: '₹${WinTheme.rupee(profile?.totalWinnings ?? 0)}',
                          label: 'Total Winnings',
                          color: WinTheme.gold,
                        ),
                        _StatCell(
                          value: '₹${WinTheme.rupee(profile?.referralEarned ?? 0)}',
                          label: 'Referral Earned',
                          color: WinTheme.blue,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ActionTile(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'View Full Wallet & Transactions',
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const WalletView()),
                      );
                      await _load();
                    },
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'ACCOUNT',
                    style: TextStyle(
                      color: WinTheme.muted,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ActionTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Edit Profile',
                    onTap: _editName,
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    icon: Icons.add_a_photo_outlined,
                    label: (profile?.profileImageUrl?.isNotEmpty == true)
                        ? 'Change profile photo'
                        : 'Add profile photo',
                    onTap: _pickProfileImage,
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    trailing: phone,
                    onTap: null,
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: () {
                      SessionService.clear();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                          builder: (_) => const PhoneLoginView(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text('Log out', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: WinTheme.muted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WinTheme.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: WinTheme.green),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              if (trailing != null)
                Text(trailing!, style: const TextStyle(color: WinTheme.muted, fontSize: 13)),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: WinTheme.muted),
            ],
          ),
        ),
      ),
    );
  }
}
