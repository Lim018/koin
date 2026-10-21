import 'package:isar_community/isar.dart';

import '../budget/budget.dart';
import 'transaction.dart';
import 'user_state.dart';

/// The only place that reads or writes Isar.
class KoinRepository {
  KoinRepository(this._isar);

  final Isar _isar;

  Future<int> addTransaction({
    required double amount,
    required String category,
    String walletSource = 'Cash',
    DateTime? timestamp,
    bool isAutoLogged = false,
    String? note,
  }) {
    if (!(amount > 0)) {
      throw ArgumentError.value(amount, 'amount', 'must be positive');
    }
    final t = Transaction()
      ..amount = amount
      ..category = category
      ..walletSource = walletSource
      ..timestamp = timestamp ?? DateTime.now()
      ..isAutoLogged = isAutoLogged
      ..note = note;
    return _isar.writeTxn(() => _isar.transactions.put(t));
  }

  Future<bool> deleteTransaction(int id) =>
      _isar.writeTxn(() => _isar.transactions.delete(id));

  /// Transactions in `[range.start, range.end)`, newest first, re-emitted on
  /// every change.
  Stream<List<Transaction>> watchTransactions(DateRange range) => _isar
      .transactions
      .where()
      .timestampBetween(range.start, range.end, includeUpper: false)
      .sortByTimestampDesc()
      .watch(fireImmediately: true);

  Stream<UserState> watchUserState() => _isar.userStates
      .watchObject(UserState.singletonId, fireImmediately: true)
      .map((s) => s ?? UserState.initial(DateTime.now()));

  Future<void> setDailyBudget(double target) {
    if (!(target > 0)) {
      throw ArgumentError.value(target, 'target', 'must be positive');
    }
    return _updateUserState((s) => s.dailyBudgetTarget = target);
  }

  Future<void> addCoins(int coins) =>
      _updateUserState((s) => s.savedCoins += coins);

  Future<void> _updateUserState(void Function(UserState) change) {
    return _isar.writeTxn(() async {
      final now = DateTime.now();
      final state =
          await _isar.userStates.get(UserState.singletonId) ??
          UserState.initial(now);
      change(state);
      state.lastUpdated = now;
      await _isar.userStates.put(state);
    });
  }
}
