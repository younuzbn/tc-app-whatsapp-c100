import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'session_service.dart';

class TicketEntry {
  const TicketEntry({required this.rate, required this.dc});

  final double rate;
  final double dc;

  factory TicketEntry.fromJson(Map<String, dynamic>? json) {
    return TicketEntry(
      rate: double.tryParse(json?['rate']?.toString() ?? '') ?? 0,
      dc: double.tryParse(json?['dc']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'rate': rate, 'dc': dc};
}

class PositionEntry {
  const PositionEntry({required this.rate, required this.dc});

  final double rate;
  final double dc;

  factory PositionEntry.fromJson(Map<String, dynamic>? json) {
    return PositionEntry(
      rate: double.tryParse(json?['rate']?.toString() ?? '') ?? 0,
      dc: double.tryParse(json?['dc']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'rate': rate, 'dc': dc};
}

class PositionDataConfig {
  const PositionDataConfig({
    required this.adminId,
    required this.entries,
  });

  final String adminId;
  final Map<String, PositionEntry> entries;

  factory PositionDataConfig.fromJson(Map<String, dynamic> json) {
    final positionMap = json['positiondata'] as Map<String, dynamic>? ?? {};
    final mapped = <String, PositionEntry>{};
    for (final key in _positionFields) {
      mapped[key] = PositionEntry.fromJson(
        positionMap[key] as Map<String, dynamic>?,
      );
    }
    return PositionDataConfig(
      adminId: json['adminId']?.toString() ?? '',
      entries: mapped,
    );
  }

  static const List<String> _positionFields = [
    'first',
    'second',
    'third',
    'fourth',
    'five',
    'guaranteesix',
    'boxfirstprice',
    'boxseries',
    'doublebox',
    'doubleboxseries',
    'triplebox',
    'single',
    'double',
  ];
}

class MobileAppConfig {
  const MobileAppConfig({
    required this.adminId,
    required this.single,
    required this.doubleType,
    required this.superType,
    required this.box,
    this.positionData,
    this.walletBalance,
  });

  final String adminId;
  final TicketEntry single;
  final TicketEntry doubleType;
  final TicketEntry superType;
  final TicketEntry box;
  /// Win / position prices from the same admin as [ticketdata] (public for customers via app-config).
  final PositionDataConfig? positionData;
  /// Customer wallet (from app-config); null for admin demo / non-mobile tokens.
  final double? walletBalance;

  factory MobileAppConfig.fromJson(Map<String, dynamic> json) {
    final ticketdata = json['ticketdata'] as Map<String, dynamic>? ?? {};
    final rawPd = json['positiondata'];
    PositionDataConfig? positionData;
    if (rawPd is Map) {
      positionData = PositionDataConfig.fromJson({
        'adminId': json['adminId']?.toString() ?? '',
        'positiondata': Map<String, dynamic>.from(rawPd),
      });
    }
    final wb = json['walletBalance'];
    final double? walletBalance = wb == null
        ? null
        : double.tryParse(wb.toString());
    return MobileAppConfig(
      adminId: json['adminId']?.toString() ?? '',
      single: TicketEntry.fromJson(ticketdata['single'] as Map<String, dynamic>?),
      doubleType: TicketEntry.fromJson(
        ticketdata['double'] as Map<String, dynamic>?,
      ),
      superType: TicketEntry.fromJson(
        ticketdata['lsksuper'] as Map<String, dynamic>?,
      ),
      box: TicketEntry.fromJson(ticketdata['box'] as Map<String, dynamic>?),
      positionData: positionData,
      walletBalance: walletBalance,
    );
  }
}

class TimeAndCountSetting {
  const TimeAndCountSetting({
    required this.timeSlot,
    required this.closeTime,
    required this.openTime,
    required this.deletionTime,
    required this.fillTime,
    required this.singleLimitEnabled,
    required this.singleLimitValue,
    required this.doubleLimitEnabled,
    required this.doubleLimitValue,
    required this.boxLimitEnabled,
    required this.boxLimitValue,
    required this.superLimitEnabled,
    required this.superLimitValue,
    this.saleChatSecondBanner,
  });

  final String timeSlot;
  final String closeTime;
  final String openTime;
  final String deletionTime;
  final String fillTime;
  final bool singleLimitEnabled;
  final int singleLimitValue;
  final bool doubleLimitEnabled;
  final int doubleLimitValue;
  final bool boxLimitEnabled;
  final int boxLimitValue;
  final bool superLimitEnabled;
  final int superLimitValue;
  /// Second yellow banner on customer sale chat for this slot; null/empty = hidden.
  final String? saleChatSecondBanner;

  factory TimeAndCountSetting.fromJson(Map<String, dynamic> json) {
    int readLimitValue(Map<String, dynamic>? data) =>
        int.tryParse(data?['value']?.toString() ?? '') ?? 0;
    bool readLimitEnabled(Map<String, dynamic>? data) => data?['enabled'] == true;

    return TimeAndCountSetting(
      timeSlot: json['timeSlot']?.toString() ?? '',
      closeTime: json['closeTime']?.toString() ?? '',
      openTime: json['openTime']?.toString() ?? '',
      deletionTime: json['deletionTime']?.toString() ?? '',
      fillTime: json['fillTime']?.toString() ?? '',
      singleLimitEnabled: readLimitEnabled(
        json['singleLimit'] as Map<String, dynamic>?,
      ),
      singleLimitValue: readLimitValue(json['singleLimit'] as Map<String, dynamic>?),
      doubleLimitEnabled: readLimitEnabled(
        json['doubleLimit'] as Map<String, dynamic>?,
      ),
      doubleLimitValue: readLimitValue(json['doubleLimit'] as Map<String, dynamic>?),
      boxLimitEnabled: readLimitEnabled(json['boxLimit'] as Map<String, dynamic>?),
      boxLimitValue: readLimitValue(json['boxLimit'] as Map<String, dynamic>?),
      superLimitEnabled: readLimitEnabled(
        json['superLimit'] as Map<String, dynamic>?,
      ),
      superLimitValue: readLimitValue(json['superLimit'] as Map<String, dynamic>?),
      saleChatSecondBanner: _parseSaleChatSecondBanner(json['saleChatSecondBanner']),
    );
  }

  static String? _parseSaleChatSecondBanner(Object? raw) {
    if (raw == null) return null;
    if (raw is String) return raw;
    return raw.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'closeTime': closeTime,
      'openTime': openTime,
      'deletionTime': deletionTime,
      'fillTime': fillTime,
      'saleChatSecondBanner': saleChatSecondBanner ?? '',
      'singleLimit': {
        'enabled': singleLimitEnabled,
        'value': singleLimitValue,
      },
      'doubleLimit': {
        'enabled': doubleLimitEnabled,
        'value': doubleLimitValue,
      },
      'boxLimit': {
        'enabled': boxLimitEnabled,
        'value': boxLimitValue,
      },
      'superLimit': {
        'enabled': superLimitEnabled,
        'value': superLimitValue,
      },
    };
  }

  /// Body for `POST /api/timeandcountsettings` (includes `timeSlot`).
  Map<String, dynamic> toCreateBody() {
    return {
      'timeSlot': timeSlot,
      ...toJson(),
    };
  }
}

class GameSettingsData {
  const GameSettingsData({
    required this.advanceBookingLimit,
    required this.advanceBookingLimitValue,
    required this.stopTheApp,
    required this.stopBooking1pm,
    required this.stopBooking3pm,
    required this.stopBooking6pm,
    required this.stopBooking8pm,
    required this.gameEnabled1pm,
    required this.gameEnabled3pm,
    required this.gameEnabled6pm,
    required this.gameEnabled8pm,
  });

  final bool advanceBookingLimit;
  final int advanceBookingLimitValue;
  final bool stopTheApp;
  final bool stopBooking1pm;
  final bool stopBooking3pm;
  final bool stopBooking6pm;
  final bool stopBooking8pm;
  final bool gameEnabled1pm;
  final bool gameEnabled3pm;
  final bool gameEnabled6pm;
  final bool gameEnabled8pm;

  factory GameSettingsData.fromJson(Map<String, dynamic> json) {
    return GameSettingsData(
      advanceBookingLimit: json['advanceBookingLimit'] == true,
      advanceBookingLimitValue:
          int.tryParse(json['advanceBookingLimitValue']?.toString() ?? '') ?? 0,
      stopTheApp: json['stopTheApp'] == true,
      stopBooking1pm: json['stopBooking1pm'] == true,
      stopBooking3pm: json['stopBooking3pm'] == true,
      stopBooking6pm: json['stopBooking6pm'] == true,
      stopBooking8pm: json['stopBooking8pm'] == true,
      gameEnabled1pm: json['gameEnabled1pm'] != false,
      gameEnabled3pm: json['gameEnabled3pm'] != false,
      gameEnabled6pm: json['gameEnabled6pm'] != false,
      gameEnabled8pm: json['gameEnabled8pm'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
    'advanceBookingLimit': advanceBookingLimit,
    'advanceBookingLimitValue': advanceBookingLimitValue,
    'stopTheApp': stopTheApp,
    'stopBooking1pm': stopBooking1pm,
    'stopBooking3pm': stopBooking3pm,
    'stopBooking6pm': stopBooking6pm,
    'stopBooking8pm': stopBooking8pm,
    'gameEnabled1pm': gameEnabled1pm,
    'gameEnabled3pm': gameEnabled3pm,
    'gameEnabled6pm': gameEnabled6pm,
    'gameEnabled8pm': gameEnabled8pm,
  };
}

class UpiPaymentConfig {
  const UpiPaymentConfig({
    this.upiId = '',
    this.qrImageUrl = '',
  });

  final String upiId;
  final String qrImageUrl;

  bool get isConfigured => upiId.contains('@');
  bool get hasQr => qrImageUrl.isNotEmpty;

  String get qrNetworkUrl => AppConfig.mediaUrl(qrImageUrl);

  factory UpiPaymentConfig.fromJson(Map<String, dynamic> json) {
    return UpiPaymentConfig(
      upiId: (json['upiId']?.toString() ?? '').trim(),
      qrImageUrl: (json['upiQrImageUrl']?.toString() ?? '').trim(),
    );
  }

  Map<String, dynamic> toJson({
    String? qrImageBase64,
    String? qrImageMime,
  }) => {
    'upiId': upiId.trim(),
    if (qrImageBase64 != null && qrImageBase64.isNotEmpty)
      'upiQrImageBase64': qrImageBase64,
    if (qrImageMime != null && qrImageMime.isNotEmpty)
      'upiQrImageMime': qrImageMime,
  };
}

class AdminMobileUser {
  const AdminMobileUser({
    required this.id,
    required this.username,
    required this.name,
    required this.phoneNumber,
    required this.displayPhoneNumber,
    required this.referralCode,
    required this.isBlocked,
    required this.deposit,
    required this.referralBalance,
    required this.winningsBalance,
    required this.withdrawableReferral,
    required this.nonWithdrawableReferral,
    required this.total,
    this.memberSince,
  });

  final String id;
  final String username;
  final String name;
  final String phoneNumber;
  final String displayPhoneNumber;
  final String referralCode;
  final bool isBlocked;
  final double deposit;
  final double referralBalance;
  final double winningsBalance;
  final double withdrawableReferral;
  final double nonWithdrawableReferral;
  final double total;
  final DateTime? memberSince;

  factory AdminMobileUser.fromJson(Map<String, dynamic> json) {
    double n(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
    final wallet = json['wallet'] as Map<String, dynamic>? ?? {};
    return AdminMobileUser(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      displayPhoneNumber:
          json['displayPhoneNumber']?.toString() ??
          json['phoneNumber']?.toString() ??
          '',
      referralCode: json['referralCode']?.toString() ?? '',
      isBlocked: json['isBlocked'] == true || json['isActive'] == false,
      deposit: n(wallet['deposit']),
      referralBalance: n(wallet['referralBalance']),
      winningsBalance: n(wallet['winningsBalance']),
      withdrawableReferral: n(
        wallet['referralWithdrawableBalance'] ?? wallet['withdrawableReferral'],
      ),
      nonWithdrawableReferral: n(
        wallet['referralNonWithdrawableBalance'] ??
            wallet['nonWithdrawableReferral'],
      ),
      total: n(wallet['total']),
      memberSince: DateTime.tryParse(json['memberSince']?.toString() ?? ''),
    );
  }
}

class AdminService {
  const AdminService();

  Future<MobileAppConfig> getMobileAppConfig() async {
    final body = await _request('/api/mobile/app-config');
    return MobileAppConfig.fromJson(body['data'] as Map<String, dynamic>? ?? {});
  }

  Future<GameSettingsData> getGameSettings() async {
    final body = await _request('/api/settings');
    return GameSettingsData.fromJson(body['data'] as Map<String, dynamic>? ?? {});
  }

  Future<void> updateGameSettings(GameSettingsData settings) async {
    await _request('/api/settings', method: 'PUT', requestBody: settings.toJson());
  }

  Future<UpiPaymentConfig> getUpiSettings() async {
    final body = await _request('/api/settings');
    return UpiPaymentConfig.fromJson(body['data'] as Map<String, dynamic>? ?? {});
  }

  Future<void> updateUpiSettings(
    UpiPaymentConfig config, {
    String? qrImageBase64,
    String? qrImageMime,
  }) async {
    await _request(
      '/api/settings',
      method: 'PUT',
      requestBody: config.toJson(
        qrImageBase64: qrImageBase64,
        qrImageMime: qrImageMime,
      ),
      timeout: const Duration(seconds: 30),
    );
  }

  Future<List<AdminMobileUser>> listMobileUsers({String query = ''}) async {
    final q = query.trim();
    final path = q.isEmpty
        ? '/api/admin/mobile-users'
        : '/api/admin/mobile-users?q=${Uri.encodeQueryComponent(q)}';
    final body = await _request(path);
    final items = body['data'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map>()
        .map((item) => AdminMobileUser.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<AdminMobileUser> setMobileUserBlocked({
    required String id,
    required bool blocked,
  }) async {
    final body = await _request(
      '/api/admin/mobile-users/$id/block',
      method: 'PUT',
      requestBody: {'blocked': blocked},
    );
    return AdminMobileUser.fromJson(body['data'] as Map<String, dynamic>? ?? {});
  }

  Future<void> deleteMobileUser(String id) async {
    await _request(
      '/api/admin/mobile-users/$id',
      method: 'DELETE',
      timeout: const Duration(seconds: 30),
    );
  }

  Future<List<TimeAndCountSetting>> getTimeAndCountSettings() async {
    final body = await _request('/api/timeandcountsettings');
    final items = body['data'] as List<dynamic>? ?? const [];
    final out = <TimeAndCountSetting>[];
    for (final e in items) {
      if (e is Map) {
        out.add(
          TimeAndCountSetting.fromJson(Map<String, dynamic>.from(e)),
        );
      }
    }
    return out;
  }

  /// One slot document (matches web `GET /api/timeandcountsettings/:timeSlot`).
  /// Returns null if that slot has no row yet (HTTP 404).
  Future<TimeAndCountSetting?> getTimeAndCountSettingByTimeSlot(
    String timeSlot,
  ) async {
    final token = SessionService.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Login required');
    }

    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/timeandcountsettings/${Uri.encodeComponent(timeSlot)}',
    );
    http.Response response;
    try {
      response =
          await http.get(uri, headers: _headers(token)).timeout(const Duration(seconds: 8));
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }

    if (response.statusCode == 404) {
      return null;
    }

    final body = _decodeBody(response.body);
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Request failed');
    }

    final raw = body['data'];
    if (raw is! Map) {
      return null;
    }
    return TimeAndCountSetting.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> updateTimeAndCountSetting(TimeAndCountSetting setting) async {
    await _request(
      '/api/timeandcountsettings/${setting.timeSlot}',
      method: 'PUT',
      requestBody: setting.toJson(),
    );
  }

  Future<void> createTimeAndCountSetting(TimeAndCountSetting setting) async {
    await _request(
      '/api/timeandcountsettings',
      method: 'POST',
      requestBody: setting.toCreateBody(),
    );
  }

  /// Creates this slot if it does not exist yet, otherwise updates (avoids editing the wrong row).
  Future<void> saveTimeAndCountSetting(TimeAndCountSetting setting) async {
    final existing = await getTimeAndCountSettingByTimeSlot(setting.timeSlot);
    if (existing == null) {
      await createTimeAndCountSetting(setting);
    } else {
      await updateTimeAndCountSetting(setting);
    }
  }

  Future<MobileAppConfig> getAdminTicketData() async {
    final body = await _request('/api/admin/profile');
    final data = body['data'] as Map<String, dynamic>? ?? {};
    return MobileAppConfig.fromJson({
      'adminId': data['_id']?.toString() ?? SessionService.userId ?? '',
      'ticketdata': data['ticketdata'] as Map<String, dynamic>? ?? {},
      'positiondata': data['positiondata'] as Map<String, dynamic>? ?? {},
    });
  }

  Future<void> updateAdminTicketData(MobileAppConfig config) async {
    final adminId = SessionService.userId ?? config.adminId;
    await _request(
      '/api/admin/$adminId',
      method: 'PUT',
      requestBody: {
        'ticketdata': {
          'single': config.single.toJson(),
          'double': config.doubleType.toJson(),
          'lsksuper': config.superType.toJson(),
          'box': config.box.toJson(),
        },
      },
    );
  }

  Future<PositionDataConfig> getAdminPositionData() async {
    final body = await _request('/api/admin/profile');
    final data = body['data'] as Map<String, dynamic>? ?? {};
    return PositionDataConfig.fromJson({
      'adminId': data['_id']?.toString() ?? SessionService.userId ?? '',
      'positiondata': data['positiondata'] as Map<String, dynamic>? ?? {},
    });
  }

  Future<void> updateAdminPositionData(PositionDataConfig config) async {
    final adminId = SessionService.userId ?? config.adminId;
    final payload = <String, dynamic>{};
    for (final entry in config.entries.entries) {
      payload[entry.key] = entry.value.toJson();
    }
    await _request(
      '/api/admin/$adminId',
      method: 'PUT',
      requestBody: {
        'positiondata': payload,
      },
    );
  }

  Future<Map<String, dynamic>> _request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? requestBody,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final token = SessionService.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Login required');
    }

    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    http.Response response;
    try {
      switch (method) {
        case 'PUT':
          response = await http
              .put(uri, headers: _headers(token), body: jsonEncode(requestBody))
              .timeout(timeout);
          break;
        case 'POST':
          response = await http
              .post(uri, headers: _headers(token), body: jsonEncode(requestBody))
              .timeout(timeout);
          break;
        case 'DELETE':
          response = await http
              .delete(uri, headers: _headers(token))
              .timeout(timeout);
          break;
        default:
          response = await http.get(uri, headers: _headers(token)).timeout(timeout);
      }
    } on SocketException {
      throw Exception(_serverUnavailableMessage());
    } on HttpException {
      throw Exception(_serverUnavailableMessage());
    } on TimeoutException {
      throw Exception(_serverUnavailableMessage());
    }

    final body = _decodeBody(response.body);
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Request failed');
    }
    return body;
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> _decodeBody(String body) {
    if (body.isEmpty) {
      return {};
    }
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  String _serverUnavailableMessage() {
    return 'Server on ${AppConfig.apiBaseUrl} is not reachable right now.';
  }
}
