import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/app_config.dart';
import '../../../services/android_image_picker.dart';
import '../../../services/app_update_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/session_service.dart';
import '../../../services/wallet_balance_store.dart';
import '../../theme/win_theme.dart';
import '../../widgets/phone_verify_sheet.dart';
import '../auth/phone_login/phone_login_view.dart';
import '../wallet/wallet_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  static const _bgAsset = 'assets/profile_bg.jpeg';

  final _auth = const AuthService();
  final _updates = const AppUpdateService();
  bool _loading = true;
  bool _uploadingPhoto = false;
  bool _checkingUpdate = false;
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
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Your name',
            labelStyle: TextStyle(color: WinTheme.muted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
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

  Future<void> _verifyPhone() async {
    if (_profile?.phoneVerified == true || SessionService.phoneVerified) return;
    final phone =
        _profile?.phoneNumber ??
        SessionService.tenDigitPhone(SessionService.displayPhoneNumber) ??
        SessionService.lastPhoneNumber ??
        '';
    if (phone.isEmpty) return;
    final ok = await showPhoneVerifyDialog(
      context,
      countryCode: '91',
      phoneNumber: phone,
    );
    if (ok && mounted) await _load(showSpinner: false);
  }

  Future<void> _checkForUpdate() async {
    if (_checkingUpdate) return;
    setState(() {
      _checkingUpdate = true;
      _error = null;
    });
    try {
      final status = await _updates.check();
      if (!mounted) return;
      if (status.hasNewer) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Version ${status.info?.latestVersion} is available. Opening download page.',
            ),
          ),
        );
        await _updates.openDownloadPage(status.info?.downloadUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You have the latest version (${status.currentVersion}).',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  void _logout() {
    SessionService.clear();
    WalletBalanceStore.instance.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const PhoneLoginView(),
      ),
      (route) => false,
    );
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
    final hasPhoto =
        profile?.profileImageUrl != null &&
        profile!.profileImageUrl!.isNotEmpty;
    final inactive = profile?.isActive == false;

    return WinStatusBar(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (!widget.embedded) ...[
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
            ],
            SafeArea(
              top: !widget.embedded,
              bottom: !widget.embedded,
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: WinTheme.green),
                    )
                  : RefreshIndicator(
                      color: WinTheme.green,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        children: [
                          _ProfileTitle(
                            showBack: !widget.embedded,
                            onBack: () => Navigator.of(context).maybePop(),
                          ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          const SizedBox(height: 16),
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
                                        backgroundImage: hasPhoto
                                            ? NetworkImage(
                                                profile.profileImageUrl!,
                                              )
                                            : null,
                                        child: hasPhoto
                                            ? null
                                            : Text(
                                                letter,
                                                style: const TextStyle(
                                                  color: Colors.white,
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
                                          decoration: BoxDecoration(
                                            color: WinTheme.green,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.black,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: _uploadingPhoto
                                              ? const Padding(
                                                  padding: EdgeInsets.all(6),
                                                  child:
                                                      CircularProgressIndicator(
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
                                Text(
                                  phone,
                                  style: const TextStyle(
                                    color: WinTheme.muted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  profile?.memberSince == null
                                      ? 'Member since —'
                                      : 'Member since ${WinTheme.monthDay(profile!.memberSince)}',
                                  style: const TextStyle(
                                    color: WinTheme.muted,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _GlassChip(
                                  child: Text.rich(
                                    TextSpan(
                                      text: 'Referral Code ',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      children: [
                                        TextSpan(
                                          text:
                                              profile?.referralCode ??
                                              SessionService.referralCode ??
                                              '—',
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
                                        color: inactive
                                            ? Colors.redAccent
                                            : WinTheme.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      inactive
                                          ? 'Account Inactive'
                                          : 'Account Active',
                                      style: TextStyle(
                                        color: inactive
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
                          _GlassCard(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 8,
                            ),
                            child: Row(
                              children: [
                                _StatCell(
                                  value:
                                      '₹${WinTheme.rupee(profile?.entryBalance ?? 0)}',
                                  label: 'Entry Balance',
                                  color: WinTheme.green,
                                  icon: Icons.account_balance_wallet_rounded,
                                ),
                                _StatCell(
                                  value:
                                      '₹${WinTheme.rupee(profile?.totalWinnings ?? 0)}',
                                  label: 'Total Winnings',
                                  color: WinTheme.gold,
                                  icon: Icons.emoji_events_rounded,
                                ),
                                _StatCell(
                                  value:
                                      '₹${WinTheme.rupee(profile?.referralEarned ?? 0)}',
                                  label: 'Referral Earned',
                                  color: WinTheme.blue,
                                  icon: Icons.card_giftcard_rounded,
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
                                MaterialPageRoute<void>(
                                  builder: (_) => const WalletView(),
                                ),
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
                            label: hasPhoto
                                ? 'Change profile photo'
                                : 'Add profile photo',
                            onTap: _pickProfileImage,
                          ),
                          const SizedBox(height: 10),
                          _MobileNumberTile(
                            phone: phone,
                            verified: profile?.phoneVerified == true ||
                                SessionService.phoneVerified,
                            onVerify: _verifyPhone,
                          ),
                          const SizedBox(height: 10),
                          _ActionTile(
                            icon: Icons.system_update_alt_rounded,
                            label: _checkingUpdate
                                ? 'Checking for update…'
                                : 'Check for update',
                            trailing: 'v${AppConfig.appVersion}',
                            onTap: _checkForUpdate,
                          ),
                          const SizedBox(height: 22),
                          Center(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _logout,
                                borderRadius: BorderRadius.circular(28),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0x33EF4444),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: const Color(0x88EF4444),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.logout_rounded,
                                        color: Colors.redAccent,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Log out',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTitle extends StatelessWidget {
  const _ProfileTitle({required this.showBack, required this.onBack});

  final bool showBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack)
          IconButton(
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            SizedBox(
              width: 46,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: WinTheme.green,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0x33101820),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x334ADE80)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x3322C55E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x554ADE80)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: WinTheme.muted, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Icon(icon, color: color, size: 18),
        ],
      ),
    );
  }
}

class _MobileNumberTile extends StatelessWidget {
  const _MobileNumberTile({
    required this.phone,
    required this.verified,
    required this.onVerify,
  });

  final String phone;
  final bool verified;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0x33101820),
            border: Border.all(color: const Color(0x334ADE80)),
          ),
          child: Row(
            children: [
              const Icon(Icons.phone_iphone_rounded, color: WinTheme.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mobile number',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phone,
                      style: const TextStyle(
                        color: WinTheme.muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      verified ? 'Verified' : 'Not verified',
                      style: TextStyle(
                        color: verified ? WinTheme.green : Colors.orangeAccent,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!verified)
                FilledButton(
                  onPressed: onVerify,
                  style: FilledButton.styleFrom(
                    backgroundColor: WinTheme.green,
                    foregroundColor: const Color(0xFF052E16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Verify',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                )
              else
                const Icon(Icons.verified_rounded, color: WinTheme.green),
            ],
          ),
        ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: const Color(0x33101820),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x334ADE80)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: WinTheme.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (trailing != null)
                    Text(
                      trailing!,
                      style: const TextStyle(
                        color: WinTheme.muted,
                        fontSize: 13,
                      ),
                    ),
                  if (onTap != null)
                    const Icon(Icons.chevron_right, color: WinTheme.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
