import 'package:flutter_test/flutter_test.dart';
import 'package:koin/core/categories.dart';
import 'package:koin/core/detected_payment.dart';

void main() {
  test('parses the URI built by KoinNotificationListener', () {
    final p = DetectedPayment.fromUri(
      Uri.parse(
        'koin://payment?amount=25000&category=Makan&wallet=GoPay&ts=1792540800000',
      ),
    )!;
    expect(p.amount, 25000);
    expect(p.category, ExpenseCategory.makan);
    expect(p.wallet, 'GoPay');
    expect(p.timestamp, DateTime.fromMillisecondsSinceEpoch(1792540800000));
  });

  test('unknown category falls back to Lainnya', () {
    final p = DetectedPayment.fromUri(
      Uri.parse('koin://payment?amount=1&category=Hack&wallet=OVO'),
    );
    expect(p?.category, ExpenseCategory.lainnya);
  });

  test('rejects malformed payloads', () {
    for (final raw in [
      'koin://payment?amount=0&wallet=GoPay',
      'koin://payment?amount=-5&wallet=GoPay',
      'koin://payment?amount=abc&wallet=GoPay',
      'koin://payment?amount=5000',
      'https://payment?amount=5000&wallet=GoPay',
      'koin://other?amount=5000&wallet=GoPay',
    ]) {
      expect(DetectedPayment.fromUri(Uri.parse(raw)), isNull, reason: raw);
    }
    expect(DetectedPayment.fromUri(null), isNull);
  });
}
