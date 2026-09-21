import 'dart:async';

import 'package:flutter/foundation.dart';

import 'session_service.dart';
import 'wallet_service.dart';

/// Shared playable/total wallet so chat, header, and wallet page stay in sync.
class WalletBalanceStore extends ChangeNotifier {
  WalletBalanceStore._();
  static final WalletBalanceStore instance = WalletBalanceStore._();

  final _service = const WalletService();
  WalletSummary? _summary;
  double? _available;
  int _generation = 0;
  bool _refreshing = false;
  bool _queuedRefresh = false;

  WalletSummary? get summary => _summary;
  double? get available =>
      _summary == null || _summary!.isAdminWallet
          ? _available
          : _summary!.available;

  void clear() {
    _generation++;
    _summary = null;
    _available = null;
    notifyListeners();
  }

  void applySummary(WalletSummary summary) {
    _summary = summary;
    _available = summary.isAdminWallet ? null : summary.available;
    notifyListeners();
  }

  /// Instant playable balance from a sale/edit/delete response.
  void setAvailable(double value) {
    _generation++;
    _available = value < 0 ? 0 : value;
    if (_summary != null && !_summary!.isAdminWallet) {
      final delta = _available! - _summary!.available;
      final nextTotal = _summary!.total + delta;
      _summary = _summary!.copyWith(
        available: _available,
        total: nextTotal < 0 ? 0 : nextTotal,
      );
    }
    notifyListeners();
  }

  void applyFromResponse(dynamic raw) {
    if (raw == null) return;
    final value = double.tryParse(raw.toString());
    if (value == null) return;
    setAvailable(value);
    unawaited(refresh());
  }

  Future<void> refresh() async {
    if (SessionService.isAdmin ||
        SessionService.authToken == null ||
        SessionService.authToken!.isEmpty) {
      return;
    }
    if (_refreshing) {
      _queuedRefresh = true;
      return;
    }
    final generation = _generation;
    _refreshing = true;
    try {
      final summary = await _service.fetchSummary();
      if (generation != _generation) {
        return;
      }
      applySummary(summary);
    } catch (_) {
      // Keep last known amounts.
    } finally {
      _refreshing = false;
      if (_queuedRefresh) {
        _queuedRefresh = false;
        unawaited(refresh());
      }
    }
  }
}
