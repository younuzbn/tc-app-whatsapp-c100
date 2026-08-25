import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:stacked/stacked.dart';

import '../../../services/admin_service.dart';
import '../../../services/result_service.dart';
import '../../../services/sales_service.dart';
import '../../../services/session_service.dart';
import '../../../services/winning_service.dart';
import '../home/game_chat_data.dart';

enum GameStatusBannerKind { countdown, gameClosed, resultPublished }

class GameChatViewModel extends BaseViewModel {
  GameChatViewModel({
    required this.game,
    SalesService? salesService,
    AdminService? adminService,
    ResultService? resultService,
    WinningService? winningService,
  }) : _salesService = salesService ?? const SalesService(),
       _adminService = adminService ?? const AdminService(),
       _resultService = resultService ?? const ResultService(),
       _winningService = winningService ?? const WinningService() {
    numberController.addListener(_onNumberFieldUpdated);
    countController.addListener(_handleInputChanged);
  }

  final GameChatData game;
  final SalesService _salesService;
  final AdminService _adminService;
  final ResultService _resultService;
  final WinningService _winningService;

  final TextEditingController numberController = TextEditingController();
  final TextEditingController countController = TextEditingController();
  final FocusNode numberFocusNode = FocusNode();
  final FocusNode countFocusNode = FocusNode();

  final List<String> numberModes = const ['1D', '2D', '3D'];
  final List<SalesRecord> sales = [];
  final List<ResultChatMessage> resultMessages = [];
  final List<WalletTopupMessage> walletTopups = [];
  final List<WinningReport> winningMessages = [];
  final ScrollController chatScrollController = ScrollController();

  String selectedNumberMode = '1D';
  String selectedOption = 'A';
  String? errorMessage;
  bool _initialised = false;
  MobileAppConfig? _config;
  TimeAndCountSetting? _timeSetting;
  Timer? _clockTimer;
  String _saleConfirmSyncKey = '';
  bool _resultPublishedForClosedSession = false;
  String? _lastResultCheckKey;
  int _resultPollTick = 0;
  bool? _wasGameClosed;
  int _salesPage = 1;
  int _salesPages = 1;
  bool loadingOlderSales = false;

  bool get hasOlderSales => _salesPage < _salesPages;

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
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final closed = isGameClosed;
      if (_wasGameClosed != closed) {
        _wasGameClosed = closed;
        if (closed) {
          unawaited(refreshClosedSessionResultStatus());
        } else {
          _resultPublishedForClosedSession = false;
          _lastResultCheckKey = null;
        }
      }
      notifyListeners();
      _syncConfirmationsIfNeeded();
      _resultPollTick++;
      // While closed, re-check published results every 20s.
      if (closed && _resultPollTick % 20 == 0) {
        unawaited(refreshClosedSessionResultStatus());
      }
      if (_resultPollTick % 20 == 0) {
        unawaited(refreshWalletTopups());
        unawaited(refreshWinnings());
        unawaited(refreshResultMessages());
      }
    });
    await _loadConfigs();
    chatScrollController.addListener(_onChatScroll);
    await loadSales();
    await refreshClosedSessionResultStatus();
  }

  Future<void> refreshResultMessages() async {
    try {
      final resultItems = await _salesService.getResultMessages(
        timeSlot: game.timeSlot,
      );
      resultMessages
        ..clear()
        ..addAll(resultItems);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshWinnings() async {
    try {
      final items = await _winningService.listMyWinnings(
        timeSlot: game.timeSlot,
      );
      winningMessages
        ..clear()
        ..addAll(items);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshWalletTopups() async {
    try {
      final topupItems = await _salesService.getMyWalletTopups();
      walletTopups
        ..clear()
        ..addAll(topupItems);
      notifyListeners();
    } catch (_) {
      // Keep previous deposit requests if refresh fails.
    }
  }

  void _onChatScroll() {
    if (!chatScrollController.hasClients) return;
    final pos = chatScrollController.position;
    if (pos.maxScrollExtent <= 0) return;
    if (pos.pixels >= pos.maxScrollExtent - 120) {
      loadOlderSales();
    }
  }

  void _syncConfirmationsIfNeeded() {
    if (sales.isEmpty || isBusy) return;
    final needsServerConfirm = sales.any(
      (sale) => isSaleConfirmed(sale) && !sale.isConfirmed,
    );
    if (!needsServerConfirm) return;
    final key = sales
        .map((s) => '${s.id}:${isSaleConfirmed(s)}')
        .join('|');
    if (key == _saleConfirmSyncKey) return;
    _saleConfirmSyncKey = key;
    unawaited(_refreshLatestSales());
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
    await refreshClosedSessionResultStatus();
    notifyListeners();
  }

  /// Result date for the draw that just closed (while between close and next open).
  DateTime? get closedSessionResultDate {
    if (!isGameClosed) return null;
    final openMinutes = _hmToMinutes(_timeSetting?.openTime);
    final closeMinutes = _hmToMinutes(_timeSetting?.closeTime);
    if (openMinutes == null || closeMinutes == null) return null;

    final now = _nowIst();
    final today = DateTime(now.year, now.month, now.day);
    final current = now.hour * 60 + now.minute;

    if (closeMinutes < openMinutes) {
      // Closed between close and open same day → today's draw.
      return today;
    }
    // Closed after close (evening) → today; before open (morning) → yesterday.
    if (current >= closeMinutes) return today;
    return today.subtract(const Duration(days: 1));
  }

  Future<void> refreshClosedSessionResultStatus() async {
    if (!isGameClosed) {
      if (_resultPublishedForClosedSession) {
        _resultPublishedForClosedSession = false;
        _lastResultCheckKey = null;
        notifyListeners();
      }
      return;
    }

    final date = closedSessionResultDate;
    if (date == null) return;
    final key =
        '${game.timeSlot}-${date.year}-${date.month}-${date.day}';
    try {
      final result = await _resultService.getResultForDate(
        timeSlot: game.timeSlot,
        date: date,
      );
      final published = result != null;
      if (_resultPublishedForClosedSession != published ||
          _lastResultCheckKey != key) {
        _resultPublishedForClosedSession = published;
        _lastResultCheckKey = key;
        notifyListeners();
        if (published) {
          unawaited(refreshResultMessages());
          unawaited(refreshWinnings());
        }
      }
    } catch (_) {
      // Keep previous status on network errors.
    }
  }

  Future<void> loadSales() async {
    setBusy(true);
    errorMessage = null;
    notifyListeners();

    try {
      final items = await _salesService.getSales(
        timeSlot: game.timeSlot,
        page: 1,
        limit: 30,
      );
      final resultItems = await _salesService.getResultMessages(
        timeSlot: game.timeSlot,
      );
      var topupItems = <WalletTopupMessage>[];
      try {
        topupItems = await _salesService.getMyWalletTopups();
      } catch (_) {}
      var winningItems = <WinningReport>[];
      try {
        winningItems = await _winningService.listMyWinnings(
          timeSlot: game.timeSlot,
        );
      } catch (_) {}
      sales
        ..clear()
        ..addAll(items.sales);
      _salesPage = items.page;
      _salesPages = items.pages;
      resultMessages
        ..clear()
        ..addAll(resultItems);
      walletTopups
        ..clear()
        ..addAll(topupItems);
      winningMessages
        ..clear()
        ..addAll(winningItems);
      _maybeLoadOlderIfShort();
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  Future<void> loadOlderSales() async {
    if (loadingOlderSales || !hasOlderSales || isBusy) return;
    loadingOlderSales = true;
    notifyListeners();
    try {
      final nextPage = _salesPage + 1;
      final items = await _salesService.getSales(
        timeSlot: game.timeSlot,
        page: nextPage,
        limit: 30,
      );
      final existing = sales.map((s) => s.id).toSet();
      sales.addAll(items.sales.where((s) => !existing.contains(s.id)));
      _salesPage = items.page;
      _salesPages = items.pages;
      _maybeLoadOlderIfShort();
    } catch (_) {
      // Keep already loaded messages if older page fails.
    } finally {
      loadingOlderSales = false;
      notifyListeners();
    }
  }

  void _maybeLoadOlderIfShort() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!chatScrollController.hasClients) return;
      if (chatScrollController.position.maxScrollExtent <= 0 && hasOlderSales) {
        loadOlderSales();
      }
    });
  }

  Future<void> _refreshLatestSales() async {
    try {
      final items = await _salesService.getSales(
        timeSlot: game.timeSlot,
        page: 1,
        limit: 30,
      );
      final byId = {for (final sale in sales) sale.id: sale};
      for (final sale in items.sales.reversed) {
        if (byId.containsKey(sale.id)) {
          final index = sales.indexWhere((s) => s.id == sale.id);
          if (index >= 0) sales[index] = sale;
        } else {
          sales.insert(0, sale);
        }
      }
      _salesPages = items.pages;
    } catch (_) {
      // Ignore background refresh errors.
    }
    notifyListeners();
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

  /// Same window rules as backend `checkGameTimeWindow` (IST).
  bool get isGameClosed {
    final openMinutes = _hmToMinutes(_timeSetting?.openTime);
    final closeMinutes = _hmToMinutes(_timeSetting?.closeTime);
    if (openMinutes == null || closeMinutes == null) return false;

    final now = _nowIst();
    final current = now.hour * 60 + now.minute;

    if (closeMinutes < openMinutes) {
      // e.g. close 11:00, open 16:00 → closed between them
      return current >= closeMinutes && current < openMinutes;
    }
    // e.g. open 09:00, close 13:00 → closed outside that window
    // or close 23:00, open 02:00 → closed overnight
    return current >= closeMinutes || current < openMinutes;
  }

  String get opensAtLabel {
    final open = _timeSetting?.openTime.trim() ?? '';
    if (open.isEmpty) return 'Opens at --';
    return 'Opens at ${_formatClockLabel(open)}';
  }

  String get headerCloseLabel {
    if (isGameClosed) {
      return 'Game is closed · $opensAtLabel';
    }
    final closeTime = _timeSetting?.closeTime.trim() ?? '';
    if (closeTime.isNotEmpty) {
      return 'Closes at ${_formatClockLabel(closeTime)}';
    }
    return game.closeLabel;
  }

  /// Live countdown while the game is open; null when closed / no times.
  String? get closeCountdownLabel {
    final remaining = timeUntilClose;
    if (remaining == null) return null;
    if (remaining.inSeconds <= 0) return '00:00:00';
    final hours = remaining.inHours.toString().padLeft(2, '0');
    final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  bool get showStatusBanner {
    if (isGameClosed) return true;
    return closeCountdownLabel != null;
  }

  GameStatusBannerKind get statusBannerKind {
    if (!isGameClosed) return GameStatusBannerKind.countdown;
    if (_resultPublishedForClosedSession) {
      return GameStatusBannerKind.resultPublished;
    }
    return GameStatusBannerKind.gameClosed;
  }

  String get statusBannerText {
    switch (statusBannerKind) {
      case GameStatusBannerKind.countdown:
        return 'Closes in ${closeCountdownLabel ?? '--:--:--'}';
      case GameStatusBannerKind.gameClosed:
        return 'Game closed';
      case GameStatusBannerKind.resultPublished:
        return 'Result published';
    }
  }

  /// Duration until the next close boundary for the current open window (IST).
  Duration? get timeUntilClose {
    if (isGameClosed) return null;
    final openMinutes = _hmToMinutes(_timeSetting?.openTime);
    final closeMinutes = _hmToMinutes(_timeSetting?.closeTime);
    if (openMinutes == null || closeMinutes == null) return null;

    final now = _nowIst();
    final current = now.hour * 60 + now.minute;
    final nowFloor = DateTime(now.year, now.month, now.day, now.hour, now.minute, now.second);

    DateTime closeAt;
    if (closeMinutes < openMinutes) {
      // Open before close, or after open until midnight then until tomorrow close.
      if (current < closeMinutes) {
        closeAt = DateTime(now.year, now.month, now.day)
            .add(Duration(minutes: closeMinutes));
      } else {
        // After open in evening → close is tomorrow.
        closeAt = DateTime(now.year, now.month, now.day)
            .add(const Duration(days: 1))
            .add(Duration(minutes: closeMinutes));
      }
    } else {
      closeAt = DateTime(now.year, now.month, now.day)
          .add(Duration(minutes: closeMinutes));
    }

    return closeAt.difference(nowFloor);
  }

  String get announcementWelcomeText {
    if (isGameClosed) {
      return 'Game is closed. $opensAtLabel.';
    }
    final closeTime = _timeSetting?.closeTime.trim() ?? '';
    if (closeTime.isNotEmpty) {
      return 'Welcome to ${game.name}! Place your bets before ${_formatClockLabel(closeTime)}.';
    }
    return 'Welcome to ${game.name}! Place your bets before close time.';
  }

  /// Edit/delete until the earlier of 5 minutes after place or game close.
  DateTime? editDeadlineForSale(SalesRecord sale) {
    final placed = sale.placedAt;
    if (placed == null) return null;
    final fiveMin = placed.add(const Duration(minutes: 5));
    final closeAt = _sessionCloseAtForPlaced(placed);
    if (closeAt == null) return fiveMin;
    return fiveMin.isBefore(closeAt) ? fiveMin : closeAt;
  }

  DateTime? _sessionCloseAtForPlaced(DateTime placed) {
    final openMinutes = _hmToMinutes(_timeSetting?.openTime);
    final closeMinutes = _hmToMinutes(_timeSetting?.closeTime);
    if (openMinutes == null || closeMinutes == null) return null;

    final ist = placed.isUtc
        ? placed.add(const Duration(hours: 5, minutes: 30))
        : placed;
    final dayStart = DateTime(ist.year, ist.month, ist.day);
    final current = ist.hour * 60 + ist.minute;

    if (closeMinutes < openMinutes) {
      if (current < closeMinutes) {
        return dayStart.add(Duration(minutes: closeMinutes));
      }
      return dayStart
          .add(const Duration(days: 1))
          .add(Duration(minutes: closeMinutes));
    }
    return dayStart.add(Duration(minutes: closeMinutes));
  }

  bool canEditOrDeleteSale(SalesRecord sale) {
    if (sale.isConfirmed) return false;
    final deadline = editDeadlineForSale(sale);
    if (deadline == null) return false;
    return DateTime.now().isBefore(deadline);
  }

  bool isSaleConfirmed(SalesRecord sale) {
    if (sale.isConfirmed) return true;
    final deadline = editDeadlineForSale(sale);
    if (deadline == null) return false;
    return !DateTime.now().isBefore(deadline);
  }

  int digitLengthForLsk(String lsk) {
    switch (lsk.toUpperCase()) {
      case 'A':
      case 'B':
      case 'C':
        return 1;
      case 'AB':
      case 'AC':
      case 'BC':
        return 2;
      default:
        return 3;
    }
  }

  DateTime _nowIst() =>
      DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

  int? _hmToMinutes(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return null;
    final parts = text.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return hour * 60 + minute;
  }

  String _formatClockLabel(String hm) {
    final minutes = _hmToMinutes(hm);
    if (minutes == null) return hm;
    final hour24 = minutes ~/ 60;
    final minute = minutes % 60;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
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

    if (isGameClosed) {
      errorMessage = 'Game is closed. $opensAtLabel.';
      notifyListeners();
      return;
    }

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

  Future<bool> updateSaleRecord({
    required SalesRecord sale,
    required String number,
    required int count,
  }) async {
    errorMessage = null;
    if (!canEditOrDeleteSale(sale)) {
      errorMessage = 'Edit allowed only within 5 minutes of placing the sale.';
      notifyListeners();
      return false;
    }

    final digits = digitLengthForLsk(sale.lsk);
    if (number.length != digits || int.tryParse(number) == null) {
      errorMessage = 'Enter a valid $digits-digit number.';
      notifyListeners();
      return false;
    }
    if (count <= 0) {
      errorMessage = 'Enter a valid count.';
      notifyListeners();
      return false;
    }

    final rate = _rateForSelection(sale.lsk);
    final camount = rate * count;
    final damount = camount;

    setBusy(true);
    notifyListeners();
    try {
      await _salesService.updateSale(
        id: sale.id,
        lsk: sale.lsk,
        number: number,
        count: count,
        damount: damount,
        camount: camount,
      );
      await loadSales();
      await refreshAppConfigAndTimes();
      return true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  Future<bool> deleteSaleRecord(SalesRecord sale) async {
    errorMessage = null;
    if (!canEditOrDeleteSale(sale)) {
      errorMessage = 'Delete allowed only within 5 minutes of placing the sale.';
      notifyListeners();
      return false;
    }

    setBusy(true);
    notifyListeners();
    try {
      await _salesService.deleteSale(id: sale.id);
      await loadSales();
      await refreshAppConfigAndTimes();
      return true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    chatScrollController.removeListener(_onChatScroll);
    chatScrollController.dispose();
    numberFocusNode.dispose();
    countFocusNode.dispose();
    numberController.dispose();
    countController.dispose();
    super.dispose();
  }
}
