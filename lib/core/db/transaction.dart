import 'package:isar_community/isar.dart';

part 'transaction.g.dart';

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
}
