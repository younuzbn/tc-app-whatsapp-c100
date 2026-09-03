import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'session_service.dart';

class GameResultData {
  const GameResultData({
    required this.id,
    required this.timeSlot,
    required this.resultDate,
    required this.createdAt,
    required this.fields,
  });

  final String id;
  final String timeSlot;
  final DateTime? resultDate;
  final DateTime? createdAt;
  final Map<String, String> fields;

  factory GameResultData.fromJson(Map<String, dynamic> json) {
    final fieldMap = <String, String>{};
    const mainFields = [
      'firstprice',
      'secondprice',
      'thirdprice',
      'fourthprice',
      'fifthplace',
    ];
    for (final field in mainFields) {
      final value = json[field];
      if (value != null && value.toString().trim().isNotEmpty) {
        fieldMap[field] = value.toString();
      }
    }
    for (var i = 6; i <= 35; i++) {
      final key = 'field$i';
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        fieldMap[key] = value.toString();
      }
    }

    return GameResultData(
      id: json['_id']?.toString() ?? '',
      timeSlot: json['timeSlot']?.toString() ?? '',
      resultDate: DateTime.tryParse(json['resultDate']?.toString() ?? ''),
      createdAt: DateTime.tryParse(
        json['createdAt']?.toString() ?? json['updatedAt']?.toString() ?? '',
      ),
      fields: fieldMap,
    );
  }
}

class ResultService {
  const ResultService();

  Future<GameResultData?> getResultForDate({
    required String timeSlot,
    required DateTime date,
  }) async {
    final data = await _request(
      '/api/result/$timeSlot?fromDate=${_day(date)}&toDate=${_day(date)}&limit=1',
      method: 'GET',
    );

    final results =
        ((data['data'] as Map<String, dynamic>?)?['results'] as List<dynamic>?) ??
        const [];
    if (results.isEmpty) {
      return null;
    }
    return GameResultData.fromJson(results.first as Map<String, dynamic>);
  }

  /// All published results across games, newest first.
  Future<List<GameResultData>> listAllResults({int limit = 60}) async {
    final data = await _request(
      '/api/result?limit=$limit',
      method: 'GET',
    );
    final results =
        ((data['data'] as Map<String, dynamic>?)?['results'] as List<dynamic>?) ??
        const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(GameResultData.fromJson)
        .toList();
  }

  /// Published results for a game (newest first from API; caller may reverse for chat).
  Future<List<GameResultData>> listResultsForTimeSlot({
    required String timeSlot,
    int limit = 60,
  }) async {
    final data = await _request(
      '/api/result/$timeSlot?limit=$limit',
      method: 'GET',
    );
    final results =
        ((data['data'] as Map<String, dynamic>?)?['results'] as List<dynamic>?) ??
        const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(GameResultData.fromJson)
        .toList();
  }

  static const List<String> topFieldKeys = <String>[
    'firstprice',
    'secondprice',
    'thirdprice',
    'fourthprice',
    'fifthplace',
  ];

  static final List<String> bottomFieldKeys = List<String>.generate(
    30,
    (index) => 'field${index + 6}',
  );

  static List<String> orderedValues(
    GameResultData result, {
    required List<String> keys,
  }) {
    return keys.map((key) => result.fields[key] ?? '').toList();
  }

  static String formatResultDateLabel(GameResultData result) {
    final date = result.resultDate;
    if (date == null) return result.timeSlot.toUpperCase();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} · ${result.timeSlot.toUpperCase()}';
  }

  static const Map<String, String> _gameNamesBySlot = {
    '1pm': 'DEAR 1PM',
    '3pm': 'KERALA 3PM',
    '6pm': 'DEAR 6PM',
    '8pm': 'DEAR 8PM',
  };

  /// Share/copy layout matching the full results page:
  /// title, 1–5 stacked vertically, COMPLIMENTS heading, then 3 columns × 10.
  static String formatResultAsText(
    GameResultData result, {
    String? gameName,
  }) {
    final date = result.resultDate ?? result.createdAt;
    final dateLabel = date == null
        ? ''
        : '${date.day.toString().padLeft(2, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.year}';
    final titleName = (gameName != null && gameName.trim().isNotEmpty)
        ? gameName.trim().toUpperCase()
        : (_gameNamesBySlot[result.timeSlot.toLowerCase()] ??
            result.timeSlot.toUpperCase());
    final title = dateLabel.isEmpty
        ? titleName
        : '$titleName ( $dateLabel )';

    final top = orderedValues(result, keys: topFieldKeys);
    final compliments = orderedValues(result, keys: bottomFieldKeys);

    final lines = <String>[title];
    for (var i = 0; i < top.length; i++) {
      final value = top[i].trim().isEmpty ? '—' : top[i].trim();
      lines.add('${i + 1} : $value');
    }

    lines.add('');
    lines.add('COMPLIMENTS');

    String cell(int index) {
      if (index >= compliments.length) return '';
      return compliments[index].trim();
    }

    for (var row = 0; row < 10; row++) {
      final a = cell(row);
      final b = cell(10 + row);
      final c = cell(20 + row);
      if (a.isEmpty && b.isEmpty && c.isEmpty) continue;
      lines.add('$a     $b     $c'.trimRight());
    }

    return lines.join('\n');
  }

  Future<void> createResult({
    required String timeSlot,
    required DateTime date,
    required Map<String, String> fields,
  }) async {
    await _request(
      '/api/result',
      method: 'POST',
      body: {
        'timeSlot': timeSlot,
        'resultDate': _day(date),
        ...fields,
      },
    );
  }

  Future<void> updateResult({
    required String id,
    required DateTime date,
    required Map<String, String> fields,
  }) async {
    await _request(
      '/api/result/$id',
      method: 'PUT',
      body: {
        'resultDate': _day(date),
        ...fields,
      },
    );
  }

  Future<Map<String, dynamic>> _request(
    String path, {
    required String method,
    Map<String, dynamic>? body,
  }) async {
    final token = SessionService.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Login required');
    }

    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    http.Response response;
    try {
      if (method == 'POST') {
        response = await http
            .post(uri, headers: _headers(token), body: jsonEncode(body))
            .timeout(const Duration(seconds: 10));
      } else if (method == 'PUT') {
        response = await http
            .put(uri, headers: _headers(token), body: jsonEncode(body))
            .timeout(const Duration(seconds: 10));
      } else {
        response = await http
            .get(uri, headers: _headers(token))
            .timeout(const Duration(seconds: 10));
      }
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }

    final decoded = _decode(response.body);
    if (response.statusCode >= 400 || decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Request failed');
    }
    return decoded;
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> _decode(String body) {
    if (body.isEmpty) return {};
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  String _day(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _serverUnavailableMessage() =>
      'Server on ${AppConfig.apiBaseUrl} is not reachable right now.';
}
