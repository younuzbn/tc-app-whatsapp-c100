import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'session_service.dart';

class WalletService {
  const WalletService();

  Future<double?> fetchBalance() async {
    final token = SessionService.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Login required');
    }
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/mobile/wallet');
    try {
      final response =
          await http.get(uri, headers: _headers(token)).timeout(const Duration(seconds: 8));
      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to load wallet');
      }
      final data = body['data'] as Map<String, dynamic>? ?? {};
      if (data['isAdminWallet'] == true) return null;
      final rawBal = data['balance'];
      if (rawBal == null) return 0;
      return double.tryParse(rawBal.toString()) ?? 0;
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }
  }

  Future<double> addFunds({
    required double amount,
    required String uti,
    required String screenshotBase64,
    String screenshotMime = 'image/jpeg',
  }) async {
    final token = SessionService.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Login required');
    }
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/mobile/wallet/add');
    try {
      final response = await http
          .post(
            uri,
            headers: _headers(token),
            body: jsonEncode({
              'amount': amount,
              'uti': uti,
              'screenshotBase64': screenshotBase64,
              'screenshotMime': screenshotMime,
            }),
          )
          .timeout(const Duration(seconds: 30));
      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to add funds');
      }
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return double.tryParse(data['balance']?.toString() ?? '') ?? 0;
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> _decodeBody(String body) {
    if (body.isEmpty) return {};
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  String _serverUnavailableMessage() {
    return 'Server on ${AppConfig.apiBaseUrl} is not reachable right now.';
  }
}
