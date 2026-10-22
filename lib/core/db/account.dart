import 'package:isar_community/isar.dart';

import '../budget/budget.dart';
import 'transaction.dart';

part 'account.g.dart';

/// Stored by ordinal; append new values at the end.
enum AccountType {
  cash('Tunai', '💵'),
  bank('Bank', '🏦'),
  ewallet('E-Wallet', '📱');

  const AccountType(this.label, this.emoji);

  final String label;
  final String emoji;
}

/// A bank account, e-wallet or cash pocket the user records money in/out of.
/// Transactions point at it by [name] (their `walletSource`).
@collection
class Account {
  Id id = Isar.autoIncrement;

  @Index(unique: true, caseSensitive: false)
  late String name;

  @enumerated
  AccountType type = AccountType.bank;

  /// Balance before the first entry recorded in Koin.
  double openingBalance = 0;

  /// Opening balance plus income minus spending recorded on this account.
  double balance(Iterable<Transaction> transactions) {
    final own = transactions.where((t) => t.walletSource == name);
    return openingBalance + incomeOf(own) - totalOf(own);
  }

  /// Seeded on first launch; same names the notification reader uses.
  static List<Account> defaults() => [
    for (final (name, type) in const [
      ('Cash', AccountType.cash),
      ('GoPay', AccountType.ewallet),
      ('OVO', AccountType.ewallet),
      ('M-Banking', AccountType.bank),
    ])
      Account()
        ..name = name
        ..type = type,
  ];
}
