import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'session_service.dart';

class SalesRecord {
  const SalesRecord({
    required this.id,
    required this.billNumber,
    required this.timeSlot,
    required this.createdBy,
    required this.lsk,
    required this.number,
    required this.count,
    required this.damount,
    required this.camount,
    required this.createdDate,
  });

  final String id;
  final String billNumber;
  final String timeSlot;
  final String createdBy;
  final String lsk;
  final String number;
  final int count;
  final double damount;
  final double camount;
  final DateTime? createdDate;

  factory SalesRecord.fromJson(Map<String, dynamic> json) {
    return SalesRecord(
      id: json['_id']?.toString() ?? '',
      billNumber: json['billNumber']?.toString() ?? '',
      timeSlot: json['timeSlot']?.toString() ?? '',
      createdBy: json['createdBy']?.toString() ?? '',
      lsk: json['lsk']?.toString() ?? '',
      number: json['number']?.toString() ?? '',
      count: int.tryParse(json['count']?.toString() ?? '') ?? 0,
      damount: double.tryParse(json['damount']?.toString() ?? '') ?? 0,
      camount: double.tryParse(json['camount']?.toString() ?? '') ?? 0,
      createdDate: DateTime.tryParse(json['createdDate']?.toString() ?? ''),
    );
  }
}

class CustomerChatSummary {
  const CustomerChatSummary({
    required this.customerId,
    required this.lastMessage,
    required this.timeSlot,
    required this.lastCreatedDate,
    required this.messageCount,
  });

  final String customerId;
  final String lastMessage;
  final String timeSlot;
  final DateTime? lastCreatedDate;
  final int messageCount;

  factory CustomerChatSummary.fromJson(Map<String, dynamic> json) {
    return CustomerChatSummary(
      customerId: json['customerId']?.toString() ?? '',
      lastMessage: json['lastMessage']?.toString() ?? '',
      timeSlot: json['timeSlot']?.toString() ?? '',
      lastCreatedDate:
          DateTime.tryParse(json['lastCreatedDate']?.toString() ?? ''),
      messageCount: int.tryParse(json['messageCount']?.toString() ?? '') ?? 0,
    );
  }
}

class ResultChatMessage {
  const ResultChatMessage({
    required this.id,
    required this.customerId,
    required this.timeSlot,
    required this.message,
    required this.resultDate,
  });

  final String id;
  final String customerId;
  final String timeSlot;
  final String message;
  final DateTime? resultDate;

  factory ResultChatMessage.fromJson(Map<String, dynamic> json) {
    return ResultChatMessage(
      id: json['_id']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      timeSlot: json['timeSlot']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      resultDate: DateTime.tryParse(
        json['resultDate']?.toString() ?? json['createdAt']?.toString() ?? '',
      ),
    );
  }
}

class WalletTopupMessage {
  const WalletTopupMessage({
    required this.id,
    required this.username,
    required this.amount,
    required this.uti,
    required this.screenshotUrl,
    required this.createdAt,
  });

  final String id;
  final String username;
  final double amount;
  final String uti;
  final String screenshotUrl;
  final DateTime? createdAt;

  factory WalletTopupMessage.fromJson(Map<String, dynamic> json) {
    final path = json['screenshotUrl']?.toString() ?? '';
    final absoluteUrl = path.startsWith('http')
        ? path
        : '${AppConfig.apiBaseUrl}$path';
    return WalletTopupMessage(
      id: json['_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      uti: json['uti']?.toString() ?? '',
      screenshotUrl: absoluteUrl,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class ConversationMessage {
  const ConversationMessage({
    required this.id,
    required this.messageType,
    required this.messageFrom,
    required this.timeSlot,
    required this.date,
    this.sale,
    this.resultMessage,
    this.walletTopup,
  });

  final String id;
  final String messageType;
  final String messageFrom;
  final String timeSlot;
  final DateTime? date;
  final SalesRecord? sale;
  final ResultChatMessage? resultMessage;
  final WalletTopupMessage? walletTopup;

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    final type = json['messageType']?.toString() ?? 'sale';
    final from = json['messageFrom']?.toString() ?? 'customer';
    if (type == 'result') {
      final result = ResultChatMessage.fromJson(json);
      return ConversationMessage(
        id: result.id,
        messageType: type,
        messageFrom: from,
        timeSlot: result.timeSlot,
        date: result.resultDate,
        resultMessage: result,
      );
    }
    if (type == 'wallet_topup') {
      final topup = WalletTopupMessage.fromJson(json);
      return ConversationMessage(
        id: topup.id,
        messageType: type,
        messageFrom: from,
        timeSlot: 'wallet',
        date: topup.createdAt,
        walletTopup: topup,
      );
    }
    final sale = SalesRecord.fromJson(json);
    return ConversationMessage(
      id: sale.id,
      messageType: type,
      messageFrom: from,
      timeSlot: sale.timeSlot,
      date: sale.createdDate,
      sale: sale,
    );
  }
}

class SalesService {
  const SalesService();

  Future<List<SalesRecord>> getSales({
    required String timeSlot,
  }) async {
    final token = SessionService.authToken;
    final username = SessionService.username;
    if (token == null || username == null) {
      throw Exception('Login required');
    }

    final now = DateTime.now();
    final day = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    try {
      final response = await http
          .get(
            Uri.parse(
              '${AppConfig.apiBaseUrl}/api/sales/list'
              '?timeSlot=$timeSlot'
              '&createdBy=$username'
              '&startDate=$day'
              '&endDate=$day'
              '&limit=100',
            ),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 8));

      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to load sales');
      }

      final data = body['data'] as Map<String, dynamic>? ?? {};
      final items = data['sales'] as List<dynamic>? ?? const [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(SalesRecord.fromJson)
          .toList();
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }
  }

  Future<List<CustomerChatSummary>> getMobileCustomerChats() async {
    final token = SessionService.authToken;
    if (token == null) {
      throw Exception('Login required');
    }

    try {
      final response = await http
          .get(
            Uri.parse('${AppConfig.apiBaseUrl}/api/sales/mobile-chats'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 8));

      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to load chats');
      }

      final items = body['data'] as List<dynamic>? ?? const [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(CustomerChatSummary.fromJson)
          .toList();
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }
  }

  Future<List<ConversationMessage>> getCustomerConversation(String customerId) async {
    final token = SessionService.authToken;
    if (token == null) {
      throw Exception('Login required');
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              '${AppConfig.apiBaseUrl}/api/sales/mobile-chats/$customerId/messages',
            ),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 8));

      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to load messages');
      }

      final items = body['data'] as List<dynamic>? ?? const [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(ConversationMessage.fromJson)
          .toList();
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }
  }

  Future<List<ResultChatMessage>> getResultMessages({
    required String timeSlot,
  }) async {
    final token = SessionService.authToken;
    if (token == null) {
      throw Exception('Login required');
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              '${AppConfig.apiBaseUrl}/api/sales/result-messages/$timeSlot',
            ),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 8));

      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to load result messages');
      }

      final items = body['data'] as List<dynamic>? ?? const [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(ResultChatMessage.fromJson)
          .toList();
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }
  }

  Future<String> addSale({
    required String timeSlot,
    required String lsk,
    required String number,
    required int count,
    required double damount,
    required double camount,
    String? customerName,
  }) async {
    final token = SessionService.authToken;
    final username = SessionService.username;
    if (token == null || username == null) {
      throw Exception('Login required');
    }

    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/sales/add/$timeSlot'),
            headers: _headers(token),
            body: jsonEncode({
              'createdBy': username,
              'customerName': customerName,
              'sales': [
                {
                  'lsk': lsk,
                  'number': number,
                  'count': count,
                  'damount': damount,
                  'camount': camount,
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 8));

      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to add sale');
      }

      return body['billNumber']?.toString() ?? '';
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }
  }

  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {};
  }

  String _serverUnavailableMessage() {
    return 'Server on ${AppConfig.apiBaseUrl} is not reachable right now.';
  }
}
