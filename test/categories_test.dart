import 'package:flutter_test/flutter_test.dart';
import 'package:koin/core/categories.dart';
import 'package:koin/core/db/custom_category.dart';
import 'package:koin/core/db/transaction.dart';

CustomCategory custom(String label, TransactionKind kind) => CustomCategory()
  ..label = label
  ..emoji = '🎓'
  ..kind = kind;

Transaction tx(String category, TransactionKind kind) => Transaction()
  ..amount = 1
  ..category = category
  ..walletSource = 'Cash'
  ..timestamp = DateTime(2026, 10, 27)
  ..kind = kind;

void main() {
  final cats = Categories([
    custom('Kuliah', TransactionKind.expense),
    custom('Freelance', TransactionKind.income),
  ]);

  test('custom categories sit before Lainnya, per kind', () {
    final expense = cats.forKind(TransactionKind.expense).map((c) => c.label);
    expect(expense.last, 'Lainnya');
    expect(expense, contains('Kuliah'));
    expect(expense, isNot(contains('Freelance')));
  });

  test('entries resolve to their custom category', () {
    expect(cats.of(tx('Kuliah', TransactionKind.expense)).emoji, '🎓');
    expect(cats.of(tx('Makan', TransactionKind.expense)).label, 'Makan');
    expect(cats.of(tx('Hilang', TransactionKind.expense)).label, 'Lainnya');
  });

  test('labels clash case-insensitively within a kind', () {
    expect(cats.isTaken('kuliah', TransactionKind.expense), isTrue);
    expect(cats.isTaken('MAKAN', TransactionKind.expense), isTrue);
    expect(cats.isTaken('Kuliah', TransactionKind.income), isFalse);
  });
}
