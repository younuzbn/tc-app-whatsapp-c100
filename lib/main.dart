import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'services/api_http.dart';
import 'services/session_service.dart';
import 'ui/theme/win_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = ApiHttpOverrides();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // google-services.json is added after the Firebase project is created.
  }
  await SessionService.restore();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(WinTheme.darkStatusBar);
  runApp(const App());
}
