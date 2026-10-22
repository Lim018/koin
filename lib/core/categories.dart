import 'package:flutter/painting.dart';

import 'db/transaction.dart';

/// What the form and diary need from either kind of category; stored by
/// [label] in `Transaction.category`.
abstract interface class TxCategory {
  String get label;
  String get emoji;
  Color get tint;

  /// The category of [t], falling back to "Lainnya" for unknown labels
  /// (e.g. auto-logged entries).
  static TxCategory of(Transaction t) => t.isIncome
      ? IncomeCategory.fromLabel(t.category)
      : ExpenseCategory.fromLabel(t.category);

  static List<TxCategory> forKind(TransactionKind kind) => switch (kind) {
    TransactionKind.expense => ExpenseCategory.values,
    TransactionKind.income => IncomeCategory.values,
  };
}

enum ExpenseCategory implements TxCategory {
  makan('Makan', '🍔', Color(0xFFFCE8DC)),
  jajan('Jajan', '☕', Color(0xFFF6EDD4)),
  transport('Transport', '🚗', Color(0xFFE5EFE0)),
  belanja('Belanja', '🛍️', Color(0xFFF2E3EC)),
  tagihan('Tagihan', '🧾', Color(0xFFE4ECEF)),
  lainnya('Lainnya', '✨', Color(0xFFF1ECE5));

  const ExpenseCategory(this.label, this.emoji, this.tint);

  @override
  final String label;
  @override
  final String emoji;
  @override
  final Color tint;

  static ExpenseCategory fromLabel(String label) =>
      values.firstWhere((c) => c.label == label, orElse: () => lainnya);
}

enum IncomeCategory implements TxCategory {
  gaji('Gaji', '💼', Color(0xFFE5EFE0)),
  bonus('Bonus/THR', '🎁', Color(0xFFF6EDD4)),
  usaha('Usaha', '💻', Color(0xFFE4ECEF)),
  transfer('Transfer', '🤝', Color(0xFFF2E3EC)),
  lainnya('Lainnya', '✨', Color(0xFFF1ECE5));

  const IncomeCategory(this.label, this.emoji, this.tint);

  @override
  final String label;
  @override
  final String emoji;
  @override
  final Color tint;

  static IncomeCategory fromLabel(String label) =>
      values.firstWhere((c) => c.label == label, orElse: () => lainnya);
}
