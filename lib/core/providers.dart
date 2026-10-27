import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import 'budget/budget.dart';
import 'categories.dart';
import 'db/account.dart';
import 'db/repository.dart';
import 'db/transaction.dart';
import 'db/user_state.dart';
import 'home_widget_sync.dart';
import 'shop/catalog.dart';

/// Opened in `main()` and injected via `ProviderScope.overrides`.
final isarProvider = Provider<Isar>(
  (ref) => throw UnimplementedError('isarProvider must be overridden'),
);

final repositoryProvider = Provider<KoinRepository>(
  (ref) => KoinRepository(ref.watch(isarProvider), onChanged: syncHomeWidget),
);

/// Today's date (local midnight); recomputes itself when the day changes so
/// "today" screens roll over even if the app stays open.
final todayProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  final untilTomorrow = dayRange(now).end.difference(now);
  final timer = Timer(
    untilTomorrow + const Duration(seconds: 1),
    ref.invalidateSelf,
  );
  ref.onDispose(timer.cancel);
  return dateOnly(now);
});

final userStateProvider = StreamProvider<UserState>(
  (ref) => ref.watch(repositoryProvider).watchUserState(),
);

final accountsProvider = StreamProvider<List<Account>>(
  (ref) => ref.watch(repositoryProvider).watchAccounts(),
);

/// Built-in plus user-added categories.
final categoriesProvider = StreamProvider<Categories>(
  (ref) =>
      ref.watch(repositoryProvider).watchCustomCategories().map(Categories.new),
);

/// Equipped pet, accessory and habitat; the default look while loading.
final lookProvider = Provider<Look>((ref) {
  final s = ref.watch(userStateProvider).valueOrNull;
  if (s == null) return defaultLook;
  return lookOf(pet: s.pet, accessory: s.accessory, habitat: s.habitat);
});

/// Live transactions in a date range, newest first.
final transactionsProvider = StreamProvider.autoDispose
    .family<List<Transaction>, DateRange>(
      (ref, range) => ref.watch(repositoryProvider).watchTransactions(range),
    );

typedef BudgetSummary = ({double spent, double budget, KokoMood mood});

/// Today's spending vs. the daily target; drives Koko's mood.
final todaySummaryProvider = Provider.autoDispose<AsyncValue<BudgetSummary>>(
  (ref) => _summarize(
    ref.watch(transactionsProvider(dayRange(ref.watch(todayProvider)))),
    ref.watch(userStateProvider),
    (u) => u.dailyBudgetTarget,
  ),
);

/// This week's spending vs. 7 × the daily target.
final weekSummaryProvider = Provider.autoDispose<AsyncValue<BudgetSummary>>(
  (ref) => _summarize(
    ref.watch(transactionsProvider(weekRange(ref.watch(todayProvider)))),
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
    (
      _,
      AsyncError(:final error, :final stackTrace),
    ) => AsyncError(error, stackTrace),
    _ => const AsyncLoading(),
  };
}
