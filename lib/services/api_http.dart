import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Flutter's default User-Agent (`Dart/x.x (dart:io)`) is often dropped by
/// Cloudflare Bot Fight Mode, which the app then reports as can't-connect.
class ApiHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.userAgent =
        'WinApp/${AppConfig.appVersion} (Linux; Android) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36';
    client.connectionTimeout = const Duration(seconds: 20);
    return client;
  }
}

const Duration apiTimeout = Duration(seconds: 20);

const String kNoInternetMessage =
    'No internet connection. Please check your network and try again.';
const String kCantConnectMessage = "Can't connect. Please try again.";

Map<String, String> jsonHeaders([Map<String, String>? extra]) => {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?extra,
    };

bool isOfflineError(Object error) {
  final text = error.toString().toLowerCase();
  const markers = [
    'failed host lookup',
    'no address associated',
    'network is unreachable',
    'network_unreachable',
    'no route to host',
    'software caused connection abort',
    'network is down',
    'socketexception: connection failed',
  ];
  if (markers.any(text.contains)) return true;

  if (error is SocketException) {
    final code = error.osError?.errorCode;
    // Android 7 = no address; 51/101 = unreachable; 65/113 = no route
    if (code == 7 ||
        code == 8 ||
        code == 51 ||
        code == 64 ||
        code == 65 ||
        code == 101 ||
        code == 113) {
      return true;
    }
  }
  return false;
}

String userFacingNetworkMessage(Object error) =>
    isOfflineError(error) ? kNoInternetMessage : kCantConnectMessage;

Exception mapNetworkError(Object error) {
  // Keep host + raw error in logcat only — never show API URL in the UI.
  print('[API] ${AppConfig.apiBaseUrl} unreachable: $error');
  return Exception(userFacingNetworkMessage(error));
}

bool isNetworkError(Object error) =>
    error is SocketException ||
    error is HttpException ||
    error is HandshakeException ||
    error is TimeoutException ||
    error is http.ClientException;
