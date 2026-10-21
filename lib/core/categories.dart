import 'package:flutter/painting.dart';

/// Fixed expense categories (stored by [label] in `Transaction.category`).
enum ExpenseCategory {
  makan('Makan', '🍔', Color(0xFFFCE8DC)),
  jajan('Jajan', '☕', Color(0xFFF6EDD4)),
  transport('Transport', '🚗', Color(0xFFE5EFE0)),
  belanja('Belanja', '🛍️', Color(0xFFF2E3EC)),
  tagihan('Tagihan', '🧾', Color(0xFFE4ECEF)),
  lainnya('Lainnya', '✨', Color(0xFFF1ECE5));

  const ExpenseCategory(this.label, this.emoji, this.tint);

  final String label;
  final String emoji;
  final Color tint;

  /// Falls back to [lainnya] for unknown values (e.g. auto-logged entries).
  static ExpenseCategory fromLabel(String label) =>
      values.firstWhere((c) => c.label == label, orElse: () => lainnya);
}

const walletSources = ['Cash', 'GoPay', 'OVO', 'M-Banking'];
