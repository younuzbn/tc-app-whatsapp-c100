import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/wallet_service.dart';
import '../../theme/win_theme.dart';

class PaymentProcessingView extends StatefulWidget {
  final String orderId;
  final double amount;
  final VoidCallback onCancel;
  final bool watchStatus;

  const PaymentProcessingView({
    super.key,
    required this.orderId,
    required this.amount,
    required this.onCancel,
    this.watchStatus = false,
  });

  @override
  State<PaymentProcessingView> createState() => _PaymentProcessingViewState();
}

class _PaymentProcessingViewState extends State<PaymentProcessingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  int _dots = 0;
  Timer? _dotsTimer;
  Timer? _pollTimer;
  bool _credited = false;
  bool _failed = false;
  final _wallet = const WalletService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _dotsTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted && !_credited && !_failed) {
        setState(() {
          _dots = (_dots + 1) % 4;
        });
      }
    });

    if (widget.watchStatus) {
      _pollOnce();
      _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollOnce());
    }
  }

  Future<void> _pollOnce() async {
    if (!mounted || _credited || _failed) return;
    try {
      final status = await _wallet.getPaymentStatus(widget.orderId);
      if (!mounted || _credited || _failed) return;
      if (status.credited) {
        _pollTimer?.cancel();
        _dotsTimer?.cancel();
        _animationController.stop();
        setState(() => _credited = true);
      } else if (status.rejected) {
        _pollTimer?.cancel();
        _dotsTimer?.cancel();
        _animationController.stop();
        setState(() => _failed = true);
      }
    } catch (_) {
      // Keep waiting; website credit can land a few seconds later.
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dotsTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  String get _dotsString => '.' * _dots;

  Future<void> _requestClose() async {
    if (_credited || _failed) {
      _finish(_credited);
      return;
    }
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text(
          'Your payment is being processed. Are you sure you want to cancel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No, Continue'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (shouldCancel == true && mounted) {
      widget.onCancel();
      _finish(false);
    }
  }

  void _finish(bool credited) {
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(credited);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _requestClose();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            _credited
                ? 'Payment Added'
                : _failed
                    ? 'Payment Failed'
                    : 'Payment Processing',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: WinTheme.green,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _requestClose,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: _credited
                ? _buildSuccess()
                : _failed
                    ? _buildFailed()
                    : _buildProcessing(),
          ),
        ),
      ),
    );
  }

  Widget _okayButton({required VoidCallback onPressed, required Color color}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Okay',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: WinTheme.green.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 60,
                      color: WinTheme.green,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Payment added',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1a1a1a),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '₹${widget.amount.toStringAsFixed(0)} has been added to your wallet.',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF666666),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        _okayButton(onPressed: () => _finish(true), color: WinTheme.green),
      ],
    );
  }

  Widget _buildFailed() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 60,
                      color: Colors.red[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Payment failed',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1a1a1a),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your payment was not successful. Please try again.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF666666),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        _okayButton(onPressed: () => _finish(false), color: Colors.red[600]!),
      ],
    );
  }

  Widget _buildProcessing() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            WinTheme.green,
                            WinTheme.green.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: WinTheme.green.withOpacity(0.28),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.access_time_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Processing Payment$_dotsString',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1a1a1a),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: WinTheme.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '₹${widget.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: WinTheme.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Please wait while we verify your payment.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        WinTheme.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Text(
                'Order ID',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.orderId,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1a1a1a),
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: Colors.blue[700],
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Complete payment in checkout. Close to cancel.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1a1a1a),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
