import 'package:isar_community/isar.dart';

part 'transaction.g.dart';

/// Stored by ordinal: rows written before income existed read as [expense].
enum TransactionKind { expense, income }

@collection
class Transaction {
  Id id = Isar.autoIncrement;

  /// Indexed: every screen queries transactions by date range.
  @Index()
  late DateTime timestamp;

  late double amount;
  late String category;
  late String walletSource; // e.g. 'Cash', 'GoPay'
  bool isAutoLogged = false;
  String? note;

  @enumerated
  TransactionKind kind = TransactionKind.expense;

  @ignore
  bool get isIncome => kind == TransactionKind.income;
}
