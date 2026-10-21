import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);
final _grouped = NumberFormat.decimalPattern('id_ID');

/// `250000` → `Rp 250.000`.
String formatRupiah(num amount) => _rupiah.format(amount);

/// `250000` → `250.000`.
String formatThousands(num amount) => _grouped.format(amount);

/// `250000` → `250rb`, `1500000` → `1,5jt` (compact chart labels).
String formatShort(num amount) {
  if (amount >= 1000000) {
    final jt = amount / 1000000;
    return '${NumberFormat('#,##0.#', 'id_ID').format(jt)}jt';
  }
  if (amount >= 1000) return '${(amount / 1000).round()}rb';
  return amount.round().toString();
}

/// Parses a grouped rupiah string (`25.000`) back to a number; null if empty.
double? parseRupiah(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.isEmpty ? null : double.parse(digits);
}

/// Keeps only digits and regroups them with `.` while typing.
class RupiahInputFormatter extends TextInputFormatter {
  const RupiahInputFormatter({this.maxDigits = 12});

  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > maxDigits) return oldValue;
    final value = parseRupiah(digits);
    final text = value == null ? '' : formatThousands(value);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
