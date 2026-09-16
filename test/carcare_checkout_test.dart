import 'package:flutter_test/flutter_test.dart';
import 'package:tc_whatsapp/services/carcare_checkout.dart';

void main() {
  test('₹1000 is 1 item with no coupon', () {
    final plan = CarCareCheckout.planForAmount(1000);
    expect(plan.qty, 1);
    expect(plan.coupon, isNull);
  });

  test('₹500 is 50% off one item', () {
    final plan = CarCareCheckout.planForAmount(500);
    expect(plan.qty, 1);
    expect(plan.coupon, 'AGENTDISC50');
    expect(
      CarCareCheckout.websiteTotal(
        plan.subtotal,
        CarCareCheckout.parseAgentDiscount(plan.coupon!)!,
      ),
      500,
    );
  });

  test('₹1 is 99.9% off', () {
    final plan = CarCareCheckout.planForAmount(1);
    expect(plan.qty, 1);
    expect(plan.coupon, 'AGENTDISC999');
    expect(
      CarCareCheckout.websiteTotal(
        plan.subtotal,
        CarCareCheckout.parseAgentDiscount(plan.coupon!)!,
      ),
      1,
    );
  });

  test('₹1500 is 2 items with 25% off', () {
    final plan = CarCareCheckout.planForAmount(1500);
    expect(plan.qty, 2);
    expect(plan.coupon, 'AGENTDISC25');
    expect(
      CarCareCheckout.websiteTotal(
        plan.subtotal,
        CarCareCheckout.parseAgentDiscount(plan.coupon!)!,
      ),
      1500,
    );
  });

  test('₹2000 is 2 items with no coupon', () {
    final plan = CarCareCheckout.planForAmount(2000);
    expect(plan.qty, 2);
    expect(plan.coupon, isNull);
  });

  test('checkout URI uses saved Indian address', () {
    final uri = CarCareCheckout.checkoutUri(
      amount: 1000,
      name: 'Arun Nair',
      phone: '9876543210',
      email: 'arun.nair.house@gmail.com',
      line1: '12/45 Kadavanthra Cross Road',
      line2: 'Near Shenoy Theatre',
      city: 'Kochi',
      state: 'Kerala',
      pincode: '682020',
      landmark: 'Opposite GCDA',
      ref: 'CC24WTESTREF',
    );
    expect(uri.queryParameters['name'], 'Arun Nair');
    expect(uri.queryParameters['phone'], '9876543210');
    expect(uri.queryParameters['line1'], '12/45 Kadavanthra Cross Road');
    expect(uri.queryParameters['city'], 'Kochi');
    expect(uri.queryParameters['state'], 'Kerala');
    expect(uri.queryParameters['pincode'], '682020');
    expect(uri.queryParameters.containsKey('coupon'), isFalse);
  });

  test('checkout URI includes wallet ref', () {
    final uri = CarCareCheckout.checkoutUri(
      amount: 500,
      phone: '7356454322',
      ref: 'CC24WTESTREF',
    );
    expect(uri.queryParameters['ref'], 'CC24WTESTREF');
    expect(uri.queryParameters['coupon'], 'AGENTDISC50');
  });

  test('matches entered rupees from 1 to 5000', () {
    for (var amount = 1; amount <= 5000; amount++) {
      final plan = CarCareCheckout.planForAmount(amount);
      final percent = plan.coupon == null
          ? 0.0
          : CarCareCheckout.parseAgentDiscount(plan.coupon!)!;
      expect(
        CarCareCheckout.websiteTotal(plan.subtotal, percent),
        amount,
        reason: 'amount=$amount qty=${plan.qty} coupon=${plan.coupon}',
      );
    }
  });
}
