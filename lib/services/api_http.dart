import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Flutter's default User-Agent (`Dart/x.x (dart:io)`) is often dropped by
/// Cloudflare Bot Fight Mode, which the app then reports as "not reachable".
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

Map<String, String> jsonHeaders([Map<String, String>? extra]) => {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?extra,
    };

Exception mapNetworkError(Object error) {
  final detail = error is SocketException
      ? error.message
      : error is http.ClientException
          ? error.message
          : error.toString();
  return Exception(
    'Server on ${AppConfig.apiBaseUrl} is not reachable right now.'
    '${detail.isEmpty ? '' : ' ($detail)'}',
  );
}

bool isNetworkError(Object error) =>
    error is SocketException ||
    error is HttpException ||
    error is HandshakeException ||
    error is TimeoutException ||
    error is http.ClientException;
