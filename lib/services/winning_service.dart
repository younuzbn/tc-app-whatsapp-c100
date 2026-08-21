import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'session_service.dart';

class WinningReport {
  const WinningReport({
    required this.id,
    required this.billNumber,
    required this.timeSlot,
    required this.resultDate,
    required this.createdBy,
    required this.lsk,
    required this.number,
    required this.count,
    required this.matchedField,
    required this.matchedResultValue,
    required this.positionRate,
    required this.positionDc,
  });

  final String id;
  final String billNumber;
  final String timeSlot;
  final DateTime? resultDate;
  final String createdBy;
  final String lsk;
  final String number;
  final int count;
  final int matchedField;
  final String matchedResultValue;
  final double positionRate;
  final double positionDc;

  double get winAmount => positionRate * count;

  factory WinningReport.fromJson(Map<String, dynamic> json) {
    return WinningReport(
      id: json['_id']?.toString() ?? '',
      billNumber: json['billNumber']?.toString() ?? '',
      timeSlot: json['timeSlot']?.toString() ?? '',
      resultDate: DateTime.tryParse(json['resultDate']?.toString() ?? ''),
      createdBy: json['createdBy']?.toString() ?? '',
      lsk: json['lsk']?.toString() ?? '',
      number: json['number']?.toString() ?? '',
      count: int.tryParse(json['count']?.toString() ?? '') ?? 0,
      matchedField: int.tryParse(json['matchedField']?.toString() ?? '') ?? 0,
      matchedResultValue: json['matchedResultValue']?.toString() ?? '',
      positionRate:
          double.tryParse(json['positionRate']?.toString() ?? '') ?? 0,
      positionDc: double.tryParse(json['positionDc']?.toString() ?? '') ?? 0,
    );
  }
}

class WinningService {
  const WinningService();

  Future<List<WinningReport>> listMyWinnings({
    String? timeSlot,
    int limit = 100,
  }) async {
    final token = SessionService.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Login required');
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              '${AppConfig.apiBaseUrl}/api/winning-reports'
              '?limit=$limit'
              '${timeSlot != null && timeSlot.isNotEmpty ? '&timeSlot=$timeSlot' : ''}',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 8));

      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to load winning reports');
      }

      final data = body['data'] as Map<String, dynamic>? ?? {};
      final items = data['winningReports'] as List<dynamic>? ?? const [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(WinningReport.fromJson)
          .toList();
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.isEmpty) return {};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {};
  }

  String _serverUnavailableMessage() {
    return 'Server on ${AppConfig.apiBaseUrl} is not reachable right now.';
  }
}
