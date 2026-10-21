import 'package:flutter_test/flutter_test.dart';
import 'package:koin/core/format.dart';

TextEditingValue type(String text) => const RupiahInputFormatter()
    .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text));

void main() {
  test('formatRupiah uses Indonesian separators', () {
    expect(formatRupiah(250000), 'Rp 250.000');
  });

  test('formatShort compacts chart labels', () {
    expect(formatShort(200000), '200rb');
    expect(formatShort(1500000), '1,5jt');
    expect(formatShort(750), '750');
  });

  test('parseRupiah ignores separators and handles empty input', () {
    expect(parseRupiah('25.000'), 25000);
    expect(parseRupiah(''), isNull);
  });

  test('RupiahInputFormatter regroups digits and drops other chars', () {
    expect(type('25000').text, '25.000');
    expect(type('1a2b3').text, '123');
    expect(type('').text, '');
  });

  test('RupiahInputFormatter rejects input beyond maxDigits', () {
    const old = TextEditingValue(text: '1');
    final result = const RupiahInputFormatter(
      maxDigits: 3,
    ).formatEditUpdate(old, const TextEditingValue(text: '1234'));
    expect(result, old);
  });
}
