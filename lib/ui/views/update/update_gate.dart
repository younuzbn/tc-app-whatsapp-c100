import 'package:flutter/material.dart';

import '../../../config/app_config.dart';
import '../../../services/app_update_service.dart';
import '../../theme/win_theme.dart';

class ForceUpdateView extends StatelessWidget {
  const ForceUpdateView({super.key, required this.status});

  final AppUpdateStatus status;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WinTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.system_update_alt_rounded, color: WinTheme.green, size: 64),
              const SizedBox(height: 20),
              const Text(
                'Update required',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Version ${status.info?.latestVersion ?? ''} is required to continue. You have ${status.currentVersion}.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: WinTheme.muted, height: 1.4),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => const AppUpdateService().openDownloadPage(
                    status.info?.downloadUrl,
                  ),
                  style: FilledButton.styleFrom(backgroundColor: WinTheme.green),
                  child: const Text(
                    'Download update',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UpdateGate extends StatefulWidget {
  const UpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> {
  final _service = const AppUpdateService();
  AppUpdateStatus? _status;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final status = await _service.check();
    if (!mounted) return;
    setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null) {
      return widget.child;
    }
    if (status.showForce) {
      return ForceUpdateView(status: status);
    }
    if (!status.showOptional) {
      return widget.child;
    }
    return Column(
      children: [
        Material(
          color: const Color(0xFF1E3A5F),
          child: SafeArea(
            bottom: false,
            child: InkWell(
              onTap: () => _service.openDownloadPage(status.info?.downloadUrl),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    const Icon(Icons.system_update_alt_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Update available · v${status.info?.latestVersion} (you have ${AppConfig.appVersion})',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Text('GET', style: TextStyle(color: WinTheme.green, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}

Widget wrapLoggedInApp(Widget child) => UpdateGate(child: child);
