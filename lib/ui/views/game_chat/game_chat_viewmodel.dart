import 'package:flutter/widgets.dart';
import 'package:stacked/stacked.dart';

import '../../../services/admin_service.dart';
import '../../../services/sales_service.dart';
import '../../../services/session_service.dart';
import '../home/game_chat_data.dart';

class GameChatViewModel extends BaseViewModel {
  GameChatViewModel({
    required this.game,
    SalesService? salesService,
    AdminService? adminService,
  }) : _salesService = salesService ?? const SalesService(),
       _adminService = adminService ?? const AdminService() {
    numberController.addListener(_onNumberFieldUpdated);
    countController.addListener(_handleInputChanged);
  }

  final GameChatData game;
  final SalesService _salesService;
  final AdminService _adminService;

  final TextEditingController numberController = TextEditingController();
  final TextEditingController countController = TextEditingController();
  final FocusNode numberFocusNode = FocusNode();
  final FocusNode countFocusNode = FocusNode();

  final List<String> numberModes = const ['1D', '2D', '3D'];
  final List<SalesRecord> sales = [];
  final List<ResultChatMessage> resultMessages = [];

  String selectedNumberMode = '1D';
  String selectedOption = 'A';
  String? errorMessage;
  bool _initialised = false;
  MobileAppConfig? _config;
  TimeAndCountSetting? _timeSetting;

  void _handleInputChanged() {
    notifyListeners();
  }

  void _onNumberFieldUpdated() {
    _handleInputChanged();
    _maybeFocusCountField();
  }

  /// After the number field has exactly [digitLength] digits, move focus to count.
  void _maybeFocusCountField() {
    final text = numberController.text;
    if (text.length != digitLength) return;
    if (int.tryParse(text) == null) return;
    if (countFocusNode.canRequestFocus) {
      countFocusNode.requestFocus();
    }
  }

  void _trimNumberIfLongerThanMode() {
    final maxLen = digitLength;
    final t = numberController.text;
    if (t.length > maxLen) {
      numberController.value = TextEditingValue(
        text: t.substring(0, maxLen),
        selection: TextSelection.collapsed(offset: maxLen),
      );
    }
  }

  Future<void> initialise() async {
    if (_initialised) return;
    _initialised = true;
    await _loadConfigs();
    await loadSales();
  }

  Future<void> _loadConfigs() async {
    await refreshAppConfigAndTimes();
  }

  Future<void> refreshAppConfigAndTimes() async {
    try {
      _config = await _adminService.getMobileAppConfig();
    } catch (_) {
      _config = null;
    }
    try {
      final timeSettings = await _adminService.getTimeAndCountSettings();
      _timeSetting = timeSettings.firstWhere(
        (item) => item.timeSlot.toLowerCase() == game.timeSlot.toLowerCase(),
        orElse: () => TimeAndCountSetting(
          timeSlot: game.timeSlot,
          closeTime: '',
          openTime: '',
          deletionTime: '',
          fillTime: '',
          singleLimitEnabled: false,
          singleLimitValue: 0,
          doubleLimitEnabled: false,
          doubleLimitValue: 0,
          boxLimitEnabled: false,
          boxLimitValue: 0,
          superLimitEnabled: false,
          superLimitValue: 0,
          saleChatSecondBanner: '',
        ),
      );
    } catch (_) {
      _timeSetting = null;
    }
    notifyListeners();
  }

  Future<void> loadSales() async {
    setBusy(true);
    errorMessage = null;
    notifyListeners();

    try {
      final items = await _salesService.getSales(timeSlot: game.timeSlot);
      final resultItems = await _salesService.getResultMessages(
        timeSlot: game.timeSlot,
      );
      sales
        ..clear()
        ..addAll(items);
      resultMessages
        ..clear()
        ..addAll(resultItems);
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  void selectGameType(String value) {
    selectedNumberMode = value;
    selectedOption = currentOptions.first;
    errorMessage = null;
    _trimNumberIfLongerThanMode();
    notifyListeners();
  }

  void selectOption(String value) {
    selectedOption = value;
    errorMessage = null;
    notifyListeners();
  }

  List<String> get currentOptions {
    switch (selectedNumberMode) {
      case '1D':
        return const ['A', 'B', 'C', 'All'];
      case '2D':
        return const ['AB', 'AC', 'BC', 'All'];
      case '3D':
      default:
        return const ['Super', 'Box', 'Both'];
    }
  }

  int get digitLength {
    switch (selectedNumberMode) {
      case '1D':
        return 1;
      case '2D':
        return 2;
      default:
        return 3;
    }
  }

  String get numberHint => '$digitLength-digit number';

  /// Shown next to stake on the composer (customer wallet from app-config).
  String get walletBalanceLabel {
    if (SessionService.isAdmin) return '—';
    final b = _config?.walletBalance;
    if (b == null) return '₹0';
    return '₹${_fmtRupee(b)}';
  }

  String get headerCloseLabel {
    final closeTime = _timeSetting?.closeTime.trim() ?? '';
    if (closeTime.isNotEmpty) {
      return 'Closes at $closeTime';
    }
    return game.closeLabel;
  }

  String get announcementWelcomeText {
    final closeTime = _timeSetting?.closeTime.trim() ?? '';
    if (closeTime.isNotEmpty) {
      return 'Welcome to ${game.name}! Place your bets before $closeTime.';
    }
    return 'Welcome to ${game.name}! Place your bets before close time.';
  }

  /// Admin-configured second yellow banner; empty hides the banner.
  String get announcementSecondBannerText =>
      (_timeSetting?.saleChatSecondBanner ?? '').trim();

  bool get showSecondSaleBanner => announcementSecondBannerText.isNotEmpty;

  String _fmtRupee(double value) {
    if (value.truncateToDouble() == value) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  List<String> get lskTargets {
    switch (selectedNumberMode) {
      case '1D':
        if (selectedOption == 'All') return const ['A', 'B', 'C'];
        return [selectedOption];
      case '2D':
        if (selectedOption == 'All') return const ['AB', 'AC', 'BC'];
        return [selectedOption];
      case '3D':
      default:
        if (selectedOption == 'Both') return const ['DEAR', 'BOX'];
        if (selectedOption == 'Box') return const ['BOX'];
        return const ['DEAR'];
    }
  }

  String get lskDisplayLabel {
    if (selectedNumberMode == '3D') {
      return selectedOption;
    }
    return selectedOption;
  }

  double _rateForLsk(String lsk) {
    final count = int.tryParse(countController.text.trim()) ?? 0;
    return _rateForSelection(lsk) * count;
  }

  int get amount {
    final total = lskTargets.fold<double>(
      0,
      (sum, lsk) => sum + _rateForLsk(lsk),
    );
    return total.round();
  }

  double _rateForSelection(String lsk) {
    final config = _config;
    if (config == null) return 0;
    switch (lsk) {
      case 'A':
      case 'B':
      case 'C':
        return config.single.rate;
      case 'AB':
      case 'AC':
      case 'BC':
        return config.doubleType.rate;
      case 'BOX':
        return config.box.rate;
      default:
        return config.superType.rate;
    }
  }

  double _dcForSelection(String lsk) => 0;

  Future<void> submitSale() async {
    final number = numberController.text.trim();
    final countText = countController.text.trim();
    final count = int.tryParse(countText);

    errorMessage = null;

    if (number.length != digitLength || int.tryParse(number) == null) {
      errorMessage = 'Enter a valid $digitLength-digit number for $selectedNumberMode.';
      notifyListeners();
      return;
    }

    if (count == null || count <= 0) {
      errorMessage = 'Enter a valid count.';
      notifyListeners();
      return;
    }

    setBusy(true);
    notifyListeners();

    try {
      for (final lsk in lskTargets) {
        final rate = _rateForSelection(lsk);
        final dc = _dcForSelection(lsk);
        await _salesService.addSale(
          timeSlot: game.timeSlot,
          lsk: lsk,
          number: number,
          count: count,
          damount: (rate * count) - (dc * count),
          camount: rate * count,
        );
      }

      numberController.clear();
      countController.clear();
      await loadSales();
      await refreshAppConfigAndTimes();
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    numberFocusNode.dispose();
    countFocusNode.dispose();
    numberController.dispose();
    countController.dispose();
    super.dispose();
  }
}
