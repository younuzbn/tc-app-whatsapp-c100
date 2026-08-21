import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'session_service.dart';

class WalletSummary {
  const WalletSummary({
    required this.total,
    required this.deposit,
    required this.available,
    required this.activityBalance,
    required this.referralBalance,
    required this.winningsBalance,
    required this.lockedBalance,
    required this.withdrawable,
    required this.isAdminWallet,
    this.payoutDetails = const PayoutDetails(),
  });

  final double total;
  final double deposit;
  final double available;
  final double activityBalance;
  final double referralBalance;
  final double winningsBalance;
  final double lockedBalance;
  final double withdrawable;
  final bool isAdminWallet;
  final PayoutDetails payoutDetails;

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    double n(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
    final activity = n(json['activityBalance']);
    final referral = n(json['referralBalance']);
    final winnings = n(json['winningsBalance']);
    final locked = n(json['lockedBalance']);
    final deposit = json['activityBalance'] != null
        ? activity
        : n(json['deposit']);
    final computedTotal = deposit + referral + winnings + locked;
    return WalletSummary(
      total: n(json['total']) > 0 ? n(json['total']) : computedTotal,
      deposit: deposit,
      available: n(json['available'] ?? json['balance']),
      activityBalance: activity,
      referralBalance: referral,
      winningsBalance: winnings,
      lockedBalance: locked,
      withdrawable: n(json['withdrawable'] ?? json['winningsBalance']),
      isAdminWallet: json['isAdminWallet'] == true,
      payoutDetails: PayoutDetails.fromJson(
        json['payoutDetails'] as Map<String, dynamic>?,
      ),
    );
  }
}

class PayoutDetails {
  const PayoutDetails({
    this.accountNumber = '',
    this.ifsc = '',
    this.upiId = '',
  });

  final String accountNumber;
  final String ifsc;
  final String upiId;

  bool get hasSavedDetails =>
      accountNumber.isNotEmpty && ifsc.isNotEmpty && upiId.isNotEmpty;

  factory PayoutDetails.fromJson(Map<String, dynamic>? json) {
    return PayoutDetails(
      accountNumber: json?['accountNumber']?.toString() ?? '',
      ifsc: json?['ifsc']?.toString() ?? '',
      upiId: json?['upiId']?.toString() ?? '',
    );
  }
}

class WithdrawRequestItem {
  const WithdrawRequestItem({
    required this.id,
    required this.username,
    required this.amount,
    required this.status,
    required this.userStatus,
    required this.accountNumber,
    required this.ifsc,
    required this.upiId,
    required this.adminNote,
    required this.createdAt,
    this.rejectReason = '',
    this.receiptUrl = '',
    this.rejectImageUrl = '',
    this.userName = '',
    this.phoneNumber = '',
    this.reviewedAt,
    this.completedAt,
  });

  final String id;
  final String username;
  final double amount;
  final String status;
  final String userStatus;
  final String accountNumber;
  final String ifsc;
  final String upiId;
  final String adminNote;
  final String rejectReason;
  final String receiptUrl;
  final String rejectImageUrl;
  final DateTime? createdAt;
  final String userName;
  final String phoneNumber;
  final DateTime? reviewedAt;
  final DateTime? completedAt;

  String get displayStatus {
    switch (status) {
      case 'completed':
        return 'Processed';
      case 'rejected':
        return 'Failed';
      default:
        return 'Processing';
    }
  }

  factory WithdrawRequestItem.fromJson(Map<String, dynamic> json) {
    String abs(dynamic value) {
      final path = value?.toString() ?? '';
      if (path.isEmpty) return '';
      if (path.startsWith('http')) return path;
      return '${AppConfig.apiBaseUrl}$path';
    }

    return WithdrawRequestItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? 'pending',
      userStatus: json['userStatus']?.toString() ??
          json['status']?.toString() ??
          'Processing',
      accountNumber: json['accountNumber']?.toString() ?? '',
      ifsc: json['ifsc']?.toString() ?? '',
      upiId: json['upiId']?.toString() ?? '',
      adminNote: json['adminNote']?.toString() ?? '',
      rejectReason: json['rejectReason']?.toString() ?? '',
      receiptUrl: abs(json['receiptUrl']),
      rejectImageUrl: abs(json['rejectImageUrl']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      userName: json['userName']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      reviewedAt: DateTime.tryParse(json['reviewedAt']?.toString() ?? ''),
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
    );
  }

  Color statusColor() {
    switch (status) {
      case 'completed':
        return const Color(0xFF22C55E);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFFACC15);
    }
  }
}

class WalletTransactionItem {
  const WalletTransactionItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.direction,
    required this.bucket,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String type;
  final double amount;
  final String direction;
  final String bucket;
  final String description;
  final DateTime? createdAt;

  factory WalletTransactionItem.fromJson(Map<String, dynamic> json) {
    return WalletTransactionItem(
      id: json['_id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      direction: json['direction']?.toString() ?? 'credit',
      bucket: json['bucket']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  String get title {
    switch (type) {
      case 'topup':
        return 'Money added';
      case 'withdraw':
        return 'Withdrawal';
      case 'bet':
        return 'Entry placed';
      case 'bet_refund':
        return 'Entry refund';
      case 'winning':
        return 'Winning credited';
      case 'welcome_bonus':
        return 'Welcome bonus';
      case 'referral_reward':
        return 'Referral bonus';
      case 'referral_commission':
        return 'Referral commission';
      default:
        return type;
    }
  }
}

class WalletService {
  const WalletService();

  Future<double?> fetchBalance() async {
    final summary = await fetchSummary();
    if (summary.isAdminWallet) return null;
    return summary.available;
  }

  Future<WalletSummary> fetchSummary() async {
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
      return WalletSummary.fromJson(data);
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }
  }

  Future<WalletSummary> addFunds({
    required double amount,
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
      return WalletSummary.fromJson(data);
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }
  }

  Future<WalletSummary> withdraw({
    required double amount,
    required String accountNumber,
    required String accountNumberConfirm,
    required String ifsc,
    required String upiId,
  }) async {
    final token = SessionService.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Login required');
    }
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/mobile/wallet/withdraw');
    try {
      final response = await http
          .post(
            uri,
            headers: _headers(token),
            body: jsonEncode({
              'amount': amount,
              'accountNumber': accountNumber,
              'accountNumberConfirm': accountNumberConfirm,
              'ifsc': ifsc,
              'upiId': upiId,
            }),
          )
          .timeout(const Duration(seconds: 12));
      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to send withdraw request');
      }
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return WalletSummary.fromJson(data);
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }
  }

  Future<({List<WithdrawRequestItem> requests, PayoutDetails payoutDetails})>
      fetchWithdrawRequests() async {
    final token = SessionService.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Login required');
    }
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/mobile/wallet/withdrawals');
    try {
      final response =
          await http.get(uri, headers: _headers(token)).timeout(const Duration(seconds: 8));
      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to load withdraw requests');
      }
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final items = data['requests'] as List<dynamic>? ?? const [];
      return (
        requests: items
            .whereType<Map<String, dynamic>>()
            .map(WithdrawRequestItem.fromJson)
            .toList(),
        payoutDetails: PayoutDetails.fromJson(
          data['payoutDetails'] as Map<String, dynamic>?,
        ),
      );
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }
  }

  Future<List<WithdrawRequestItem>> fetchAdminWithdrawRequests({String? status}) async {
    final token = SessionService.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Login required');
    }
    final query = (status != null && status.isNotEmpty) ? '?status=$status' : '';
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/admin/withdrawals$query');
    try {
      final response =
          await http.get(uri, headers: _headers(token)).timeout(const Duration(seconds: 10));
      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to load withdraw requests');
      }
      final items = body['data'] as List<dynamic>? ?? const [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(WithdrawRequestItem.fromJson)
          .toList();
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }
  }

  Future<WithdrawRequestItem> updateAdminWithdrawRequest({
    required String id,
    required String action,
    String note = '',
    String rejectReason = '',
    String? imageBase64,
    String imageMime = 'image/jpeg',
  }) async {
    final token = SessionService.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Login required');
    }
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/admin/withdrawals/$id');
    try {
      final response = await http
          .put(
            uri,
            headers: _headers(token),
            body: jsonEncode({
              'action': action,
              'note': note,
              'rejectReason': rejectReason,
              if (imageBase64 != null && imageBase64.isNotEmpty)
                'imageBase64': imageBase64,
              if (imageBase64 != null && imageBase64.isNotEmpty)
                'imageMime': imageMime,
            }),
          )
          .timeout(const Duration(seconds: 30));
      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to update request');
      }
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return WithdrawRequestItem.fromJson(data);
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }
  }

  Future<void> verifyAdminTopup(String id, {String action = 'verify'}) async {
    final token = SessionService.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Login required');
    }
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/admin/wallet-topups/$id');
    try {
      final response = await http
          .put(
            uri,
            headers: _headers(token),
            body: jsonEncode({'action': action}),
          )
          .timeout(const Duration(seconds: 20));
      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to update add money request');
      }
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }
  }

  Future<List<WalletTransactionItem>> fetchTransactions({int limit = 50}) async {
    final token = SessionService.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Login required');
    }
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/mobile/wallet/transactions?limit=$limit',
    );
    try {
      final response =
          await http.get(uri, headers: _headers(token)).timeout(const Duration(seconds: 8));
      final body = _decodeBody(response.body);
      if (response.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to load transactions');
      }
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final items = data['transactions'] as List<dynamic>? ?? const [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(WalletTransactionItem.fromJson)
          .toList();
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
