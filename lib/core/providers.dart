import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import 'budget/budget.dart';
import 'db/repository.dart';
import 'db/transaction.dart';
import 'db/user_state.dart';

/// Opened in `main()` and injected via `ProviderScope.overrides`.
final isarProvider = Provider<Isar>(
  (ref) => throw UnimplementedError('isarProvider must be overridden'),
);

final repositoryProvider = Provider<KoinRepository>(
  (ref) => KoinRepository(ref.watch(isarProvider)),
);

final userStateProvider = StreamProvider<UserState>(
  (ref) => ref.watch(repositoryProvider).watchUserState(),
);

final todayTransactionsProvider = StreamProvider<List<Transaction>>(
  (ref) =>
      ref.watch(repositoryProvider).watchTransactions(dayRange(DateTime.now())),
);

final weekTransactionsProvider = StreamProvider<List<Transaction>>(
  (ref) =>
      ref.watch(repositoryProvider).watchTransactions(weekRange(DateTime.now())),
);

typedef BudgetSummary = ({
  double spent,
  double budget,
  KokoMood mood,
});

/// Today's spending vs. the daily target; drives Koko's mood.
final todaySummaryProvider = Provider<AsyncValue<BudgetSummary>>(
  (ref) => _summarize(
    ref.watch(todayTransactionsProvider),
    ref.watch(userStateProvider),
    (u) => u.dailyBudgetTarget,
  ),
);

/// This week's spending vs. 7 × the daily target.
final weekSummaryProvider = Provider<AsyncValue<BudgetSummary>>(
  (ref) => _summarize(
    ref.watch(weekTransactionsProvider),
    ref.watch(userStateProvider),
    (u) => weeklyBudget(u.dailyBudgetTarget),
  ),
);

AsyncValue<BudgetSummary> _summarize(
  AsyncValue<List<Transaction>> txs,
  AsyncValue<UserState> user,
  double Function(UserState) budgetOf,
) {
  return switch ((txs, user)) {
    (AsyncData(value: final t), AsyncData(value: final u)) => AsyncData((
      spent: totalOf(t),
      budget: budgetOf(u),
      mood: moodFor(spent: totalOf(t), budget: budgetOf(u)),
    )),
    (AsyncError(:final error, :final stackTrace), _) ||
    (_, AsyncError(:final error, :final stackTrace)) => AsyncError(
      error,
      stackTrace,
    ),
    _ => const AsyncLoading(),
  };
}
