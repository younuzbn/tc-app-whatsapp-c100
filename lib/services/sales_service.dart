import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'session_service.dart';
import 'winning_service.dart';

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
    this.createdAt,
    this.confirmedAt,
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
  final DateTime? createdAt;
  final DateTime? confirmedAt;

  /// Prefer createdAt for the edit/delete window.
  DateTime? get placedAt => createdAt ?? createdDate;

  bool get isConfirmed => confirmedAt != null;

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
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      confirmedAt: DateTime.tryParse(json['confirmedAt']?.toString() ?? ''),
    );
  }
}

class SaleAckMessage {
  const SaleAckMessage({
    required this.id,
    required this.salesId,
    required this.timeSlot,
    required this.message,
    required this.confirmedAt,
  });

  final String id;
  final String salesId;
  final String timeSlot;
  final String message;
  final DateTime? confirmedAt;

  factory SaleAckMessage.fromJson(Map<String, dynamic> json) {
    return SaleAckMessage(
      id: json['_id']?.toString() ?? '',
      salesId: json['salesId']?.toString() ?? '',
      timeSlot: json['timeSlot']?.toString() ?? '',
      message: json['message']?.toString() ?? '👍',
      confirmedAt: DateTime.tryParse(
        json['confirmedAt']?.toString() ??
            json['messageDate']?.toString() ??
            '',
      ),
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
    this.status = 'credited',
    this.userStatus = 'Processed',
  });

  final String id;
  final String username;
  final double amount;
  final String uti;
  final String screenshotUrl;
  final DateTime? createdAt;
  final String status;
  final String userStatus;

  bool get isPending => status == 'pending';
  bool get isCredited => status == 'credited';
  bool get isRejected => status == 'rejected';

  factory WalletTopupMessage.fromJson(Map<String, dynamic> json) {
    final path = json['screenshotUrl']?.toString() ?? '';
    final absoluteUrl = path.isEmpty
        ? ''
        : path.startsWith('http')
        ? path
        : '${AppConfig.apiBaseUrl}$path';
    var id = json['topupId']?.toString() ?? json['_id']?.toString() ?? '';
    if (id.startsWith('topup-')) {
      id = id.substring(6);
    }
    final status = json['status']?.toString() ?? 'credited';
    final fallbackStatus = status == 'pending'
        ? 'Processing'
        : status == 'rejected'
        ? 'Failed'
        : 'Processed';
    return WalletTopupMessage(
      id: id,
      username: json['username']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      uti: json['uti']?.toString() ?? '',
      screenshotUrl: absoluteUrl,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      status: status,
      userStatus: json['userStatus']?.toString().isNotEmpty == true
          ? json['userStatus'].toString()
          : fallbackStatus,
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
    this.saleAck,
    this.winning,
  });

  final String id;
  final String messageType;
  final String messageFrom;
  final String timeSlot;
  final DateTime? date;
  final SalesRecord? sale;
  final ResultChatMessage? resultMessage;
  final WalletTopupMessage? walletTopup;
  final SaleAckMessage? saleAck;
  final WinningReport? winning;

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
    if (type == 'winning') {
      final winning = WinningReport.fromJson(json);
      return ConversationMessage(
        id: winning.id,
        messageType: type,
        messageFrom: from,
        timeSlot: winning.timeSlot,
        date: winning.createdAt ?? winning.resultDate,
        winning: winning,
      );
    }
    if (type == 'sale_ack') {
      final ack = SaleAckMessage.fromJson(json);
      return ConversationMessage(
        id: ack.id,
        messageType: type,
        messageFrom: from,
        timeSlot: ack.timeSlot,
        date: ack.confirmedAt,
        saleAck: ack,
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

class SalesPage {
  const SalesPage({
    required this.sales,
    required this.page,
    required this.pages,
    required this.total,
  });

  final List<SalesRecord> sales;
  final int page;
  final int pages;
  final int total;

  bool get hasMore => page < pages;
}

class SalesService {
  const SalesService();

  Future<SalesPage> getSales({
    String? timeSlot,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 30,
  }) async {
    final token = SessionService.authToken;
    final username = SessionService.username;
    if (token == null || username == null) {
      throw Exception('Login required');
    }

    final params = <String, String>{
      'createdBy': username,
      'page': '$page',
      'limit': '$limit',
      if (timeSlot != null && timeSlot.isNotEmpty) 'timeSlot': timeSlot,
      if (startDate != null) 'startDate': _day(startDate),
      if (endDate != null) 'endDate': _day(endDate),
    };
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');

    try {
      final response = await http
          .get(
            Uri.parse('${AppConfig.apiBaseUrl}/api/sales/list?$query'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 8));

      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to load sales');
      }

      final data = body['data'] as Map<String, dynamic>? ?? {};
      final items = data['sales'] as List<dynamic>? ?? const [];
      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
      return SalesPage(
        sales: items
            .whereType<Map<String, dynamic>>()
            .map(SalesRecord.fromJson)
            .toList(),
        page: int.tryParse(pagination['page']?.toString() ?? '') ?? page,
        pages: int.tryParse(pagination['pages']?.toString() ?? '') ?? 1,
        total: int.tryParse(pagination['total']?.toString() ?? '') ?? items.length,
      );
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }
  }

  String _day(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
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

  Future<List<WalletTopupMessage>> getMyWalletTopups() async {
    final token = SessionService.authToken;
    if (token == null) {
      throw Exception('Login required');
    }

    try {
      final response = await http
          .get(
            Uri.parse('${AppConfig.apiBaseUrl}/api/mobile/wallet/topups'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 8));

      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to load deposit requests');
      }

      final items = body['data'] as List<dynamic>? ?? const [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(WalletTopupMessage.fromJson)
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

  Future<void> updateSale({
    required String id,
    required String lsk,
    required String number,
    required int count,
    required double damount,
    required double camount,
  }) async {
    final token = SessionService.authToken;
    if (token == null) {
      throw Exception('Login required');
    }

    try {
      final response = await http
          .put(
            Uri.parse('${AppConfig.apiBaseUrl}/api/sales/$id'),
            headers: _headers(token),
            body: jsonEncode({
              'lsk': lsk,
              'number': number,
              'count': count,
              'damount': damount,
              'camount': camount,
            }),
          )
          .timeout(const Duration(seconds: 8));

      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to update sale');
      }
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }
  }

  Future<void> deleteSale({required String id}) async {
    final token = SessionService.authToken;
    if (token == null) {
      throw Exception('Login required');
    }

    try {
      final response = await http
          .delete(
            Uri.parse('${AppConfig.apiBaseUrl}/api/sales/$id'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 8));

      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to delete sale');
      }
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
