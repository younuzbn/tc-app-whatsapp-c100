import 'package:flutter/material.dart';

import '../services/session_service.dart';
import '../ui/theme/win_theme.dart';
import '../ui/views/admin/admin_home_view.dart';
import '../ui/views/auth/phone_login/phone_login_view.dart';
import '../ui/views/home/home_view.dart';
import '../ui/views/update/update_gate.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  Widget? _home;

  @override
  void initState() {
    super.initState();
    _openInitialRoute();
  }

  Future<void> _openInitialRoute() async {
    await SessionService.restore();
    if (!mounted) return;
    setState(() {
      if (!SessionService.isLoggedIn) {
        _home = const PhoneLoginView();
        return;
      }
      _home = wrapLoggedInApp(
        SessionService.isAdmin
            ? const AdminHomeView()
            : HomeView(
                displayPhoneNumber:
                    SessionService.displayPhoneNumber ??
                    SessionService.username ??
                    '',
              ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Win App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF128C7E)),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: WinTheme.lightStatusBar,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: UnderlineInputBorder(),
        ),
      ),
      home: _home ??
          const Scaffold(
            backgroundColor: WinTheme.bg,
            body: Center(
              child: CircularProgressIndicator(color: WinTheme.green),
            ),
          ),
    );
  }
}
