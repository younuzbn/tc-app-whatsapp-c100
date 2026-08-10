import 'package:stacked/stacked.dart';

import '../../../services/session_service.dart';
import '../../../services/wallet_service.dart';

enum HomeCategory { draws, results }

class HomeViewModel extends BaseViewModel {
  HomeViewModel({required this.displayPhoneNumber}) {
    Future.microtask(refreshWallet);
  }

  final String displayPhoneNumber;
  final _walletService = const WalletService();

  bool _walletLoading = true;
  String _walletChipText = '';
  HomeCategory _selectedCategory = HomeCategory.draws;

  /// Text next to the wallet icon (e.g. `₹500`, `—`, or empty while loading).
  String get walletChipText => _walletChipText;

  bool get walletLoading => _walletLoading;

  HomeCategory get selectedCategory => _selectedCategory;

  void selectCategory(HomeCategory category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> refreshWallet() async {
    _walletLoading = true;
    _walletChipText = '';
    notifyListeners();
    try {
      if (SessionService.isAdmin) {
        _walletChipText = '—';
      } else {
        final balance = await _walletService.fetchBalance();
        if (balance == null) {
          _walletChipText = '—';
        } else {
          _walletChipText = '₹${_fmtRupee(balance)}';
        }
      }
    } catch (_) {
      _walletChipText = '—';
    } finally {
      _walletLoading = false;
      notifyListeners();
    }
  }

  String _fmtRupee(double value) {
    if (value.truncateToDouble() == value) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }
}
