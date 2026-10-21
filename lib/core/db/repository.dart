import 'package:isar_community/isar.dart';

import '../budget/budget.dart';
import 'transaction.dart';
import 'user_state.dart';

/// The only place that reads or writes Isar.
class KoinRepository {
  KoinRepository(this._isar, {this.onChanged});

  final Isar _isar;

  /// Runs after every successful write (keeps the home widget in sync).
  final Future<void> Function(KoinRepository repo)? onChanged;

  Future<T> _write<T>(Future<T> Function() body) async {
    final result = await _isar.writeTxn(body);
    await onChanged?.call(this);
    return result;
  }

  Future<int> addTransaction({
    required double amount,
    required String category,
    String walletSource = 'Cash',
    DateTime? timestamp,
    bool isAutoLogged = false,
    String? note,
    TransactionKind kind = TransactionKind.expense,
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
      ..note = note
      ..kind = kind;
    return _write(() => _isar.transactions.put(t));
  }

  /// Overwrites the stored row with the same [Transaction.id].
  Future<void> updateTransaction(Transaction t) {
    if (!(t.amount > 0)) {
      throw ArgumentError.value(t.amount, 'amount', 'must be positive');
    }
    return _write(() => _isar.transactions.put(t));
  }

  Future<bool> deleteTransaction(int id) =>
      _write(() => _isar.transactions.delete(id));

  /// Transactions in `[range.start, range.end)`, newest first, re-emitted on
  /// every change.
  Stream<List<Transaction>> watchTransactions(DateRange range) => _isar
      .transactions
      .where()
      .timestampBetween(range.start, range.end, includeUpper: false)
      .sortByTimestampDesc()
      .watch(fireImmediately: true);

  /// Today's total and the daily target, read once.
  Future<({double spent, double budget})> todaySnapshot() async {
    final range = dayRange(DateTime.now());
    final txs = await _isar.transactions
        .where()
        .timestampBetween(range.start, range.end, includeUpper: false)
        .findAll();
    final user = await _isar.userStates.get(UserState.singletonId);
    return (
      spent: totalOf(txs),
      budget: (user ?? UserState.initial(DateTime.now())).dailyBudgetTarget,
    );
  }

  Stream<UserState> watchUserState() => _isar.userStates
      .watchObject(UserState.singletonId, fireImmediately: true)
      .map((s) => s ?? UserState.initial(DateTime.now()));

  Future<void> setDailyBudget(double target) {
    if (!(target > 0)) {
      throw ArgumentError.value(target, 'target', 'must be positive');
    }
    return _updateUserState((s) => s.dailyBudgetTarget = target);
  }

  /// Grants [coinsPerDay] for every finished day since the last evaluation
  /// that stayed within budget. Idempotent: each day is evaluated once.
  /// Returns the coins granted now.
  Future<int> awardDailyCoins(DateTime now) async {
    final today = dateOnly(now);
    var awarded = 0;
    await _write(() async {
      final state =
          await _isar.userStates.get(UserState.singletonId) ??
          UserState.initial(now);
      final through = state.coinsAwardedThrough;
      final DateTime from;
      if (through != null) {
        from = DateTime(through.year, through.month, through.day + 1);
      } else {
        // First run: start at the oldest entry (none → nothing to reward).
        final oldest = await _isar.transactions
            .where()
            .sortByTimestamp()
            .findFirst();
        from = oldest == null ? today : dateOnly(oldest.timestamp);
      }
      if (!from.isBefore(today) && through != null) return;

      final txs = await _isar.transactions
          .where()
          .timestampBetween(from, today, includeUpper: false)
          .findAll();
      awarded = coinsEarned(
        totals: dailyTotals(txs),
        dailyBudget: state.dailyBudgetTarget,
        from: from,
        until: today,
      );
      state
        ..savedCoins += awarded
        ..coinsAwardedThrough = DateTime(today.year, today.month, today.day - 1)
        ..lastUpdated = now;
      await _isar.userStates.put(state);
    });
    return awarded;
  }

  Future<void> _updateUserState(void Function(UserState) change) {
    return _write(() async {
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
