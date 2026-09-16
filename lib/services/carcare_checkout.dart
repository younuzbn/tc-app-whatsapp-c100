class CarCareCheckoutPlan {
  const CarCareCheckoutPlan({
    required this.qty,
    required this.subtotal,
    this.coupon,
  });

  final int qty;
  final int subtotal;
  final String? coupon;
}

class CarCareCheckout {
  static const productId = '2';
  static const unitPrice = 1000;
  static const checkoutBase = 'https://www.carcare24.shop/checkout/payment';

  static const defaultName = 'test';
  static const defaultPhone = '7356454322';
  static const defaultEmail = 'test@gmail.com';
  static const defaultLine1 = 'test address line 1';
  static const defaultLine2 = 'tets address line 2';
  static const defaultCity = 'test';
  static const defaultState = 'Kerala';
  static const defaultPincode = '673293';

  /// Pick qty + AGENTDISC so the ₹1000 product totals [amount] rupees.
  /// ₹1000 → 1 item, no coupon. ₹500 → 50% off. ₹1500 → 2 items + 25% off.
  static CarCareCheckoutPlan planForAmount(int amount) {
    final pay = amount.clamp(1, unitPrice * 99);
    final qty = (pay + unitPrice - 1) ~/ unitPrice;
    final subtotal = qty * unitPrice;
    if (pay >= subtotal) {
      return CarCareCheckoutPlan(qty: qty, subtotal: subtotal);
    }
    return CarCareCheckoutPlan(
      qty: qty,
      subtotal: subtotal,
      coupon: _couponFor(subtotal: subtotal, pay: pay),
    );
  }

  static Uri checkoutUri({
    required int amount,
    String? name,
    String? phone,
    String? email,
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? pincode,
    String? landmark,
    String? ref,
  }) {
    final plan = planForAmount(amount);
    return Uri.parse(checkoutBase).replace(
      queryParameters: {
        'product': productId,
        'qty': '${plan.qty}',
        'name': _nonEmpty(name, defaultName),
        'phone': _digitsPhone(phone),
        'email': _nonEmpty(email, defaultEmail),
        'line1': _nonEmpty(line1, defaultLine1),
        'line2': _nonEmpty(line2, defaultLine2),
        'city': _nonEmpty(city, defaultCity),
        'state': _nonEmpty(state, defaultState),
        'pincode': _pincode(pincode),
        if (_nonEmpty(landmark, '').isNotEmpty) 'landmark': landmark!.trim(),
        if (plan.coupon != null) 'coupon': plan.coupon!,
        if (ref != null && ref.trim().isNotEmpty) 'ref': ref.trim(),
      },
    );
  }

  static String? _couponFor({required int subtotal, required int pay}) {
    final needed = (subtotal - pay) * 100 / subtotal;
    for (final code in _candidateCodes(needed)) {
      final percent = parseAgentDiscount(code);
      if (percent != null && websiteTotal(subtotal, percent) == pay) {
        return code;
      }
    }
    for (var tenths = 1; tenths <= 1000; tenths++) {
      final percent = tenths / 10;
      if (websiteTotal(subtotal, percent) == pay) {
        return _formatCode(percent);
      }
    }
    return _formatCode(needed);
  }

  static Iterable<String> _candidateCodes(double percent) sync* {
    yield _formatCode(percent);
    final asInt = percent.round();
    if (asInt >= 1 && asInt <= 100) yield 'AGENTDISC$asInt';
    final tenths = (percent * 10).round();
    if (tenths >= 1 && tenths <= 1000) {
      yield _formatCode(tenths / 10);
    }
  }

  static String _formatCode(double percent) {
    if ((percent - percent.round()).abs() < 1e-9) {
      final n = percent.round().clamp(1, 100);
      return 'AGENTDISC$n';
    }
    final tenths = (percent * 10).round();
    if ((tenths / 10 - percent).abs() < 1e-9 && tenths.toString().length >= 3) {
      return 'AGENTDISC$tenths';
    }
    var text = percent.toStringAsFixed(10);
    while (text.contains('.') && (text.endsWith('0') || text.endsWith('.'))) {
      text = text.substring(0, text.length - 1);
    }
    return 'AGENTDISC$text';
  }

  /// Mirrors carcare24.shop `parseAgentDiscount`.
  static double? parseAgentDiscount(String raw) {
    final code = raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    final match = RegExp(r'^(?:AGENTDISC)?(\d+(?:\.\d+)?)$').firstMatch(code);
    if (match == null) return null;
    final amount = match.group(1)!;
    final double percent;
    if (amount.contains('.')) {
      percent = double.parse(amount);
    } else if (amount == '100') {
      percent = 100;
    } else if (amount.length <= 2) {
      percent = double.parse(amount);
    } else {
      percent = double.parse(
        '${amount.substring(0, amount.length - 1)}.${amount[amount.length - 1]}',
      );
    }
    if (percent <= 0 || percent > 100) return null;
    return percent;
  }

  /// Mirrors carcare24.shop `cartTotals` with free shipping (product 2).
  static int websiteTotal(int subtotal, double percent) {
    final discount = (subtotal * percent / 100).round();
    return (subtotal - discount).clamp(0, subtotal);
  }

  static String _digitsPhone(String? raw) {
    final digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    final ten = digits.length >= 10
        ? digits.substring(digits.length - 10)
        : digits;
    if (RegExp(r'^[6-9]\d{9}$').hasMatch(ten)) return ten;
    return defaultPhone;
  }

  static String _pincode(String? raw) {
    final digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 6) return digits.substring(0, 6);
    return defaultPincode;
  }

  static String _nonEmpty(String? value, String fallback) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}
