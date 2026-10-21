/// Pure budget rules shared by the app, the home widget and the calendar.
library;

import '../db/transaction.dart';

enum KokoMood { happy, neutral, grumpy }

/// Spending up to this fraction of the budget keeps Koko happy.
const happyThreshold = 0.8;

KokoMood moodFor({required double spent, required double budget}) {
  if (budget <= 0) return spent > 0 ? KokoMood.grumpy : KokoMood.happy;
  final ratio = spent / budget;
  if (ratio <= happyThreshold) return KokoMood.happy;
  if (ratio <= 1) return KokoMood.neutral;
  return KokoMood.grumpy;
}

bool isOverBudget({required double spent, required double budget}) =>
    spent > budget;

/// A half-open local-time range `[start, end)`.
typedef DateRange = ({DateTime start, DateTime end});

DateTime dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);

DateRange dayRange(DateTime t) {
  final start = dateOnly(t);
  return (start: start, end: DateTime(start.year, start.month, start.day + 1));
}

/// Week starting on Monday, as in the design (Sen … Min).
DateRange weekRange(DateTime t) {
  final day = dateOnly(t);
  final start = DateTime(day.year, day.month, day.day - (day.weekday - 1));
  return (start: start, end: DateTime(start.year, start.month, start.day + 7));
}

DateRange monthRange(DateTime t) =>
    (start: DateTime(t.year, t.month), end: DateTime(t.year, t.month + 1));

double weeklyBudget(double dailyBudget) => dailyBudget * 7;

double totalOf(Iterable<Transaction> transactions) =>
    transactions.fold(0, (sum, t) => sum + t.amount);

/// Sums amounts per calendar day (keyed by local midnight).
Map<DateTime, double> dailyTotals(Iterable<Transaction> transactions) {
  final totals = <DateTime, double>{};
  for (final t in transactions) {
    final key = dateOnly(t.timestamp);
    totals[key] = (totals[key] ?? 0) + t.amount;
  }
  return totals;
}

/// Reward for each finished day that has entries and stays within budget.
const coinsPerDay = 50;

/// Coins earned for the finished days in `[from, until)`. Days without any
/// entry earn nothing, so not using the app is never rewarded.
int coinsEarned({
  required Map<DateTime, double> totals,
  required double dailyBudget,
  required DateTime from,
  required DateTime until,
}) {
  var days = 0;
  for (final MapEntry(key: day, value: spent) in totals.entries) {
    if (!day.isBefore(from) && day.isBefore(until) && spent <= dailyBudget) {
      days++;
    }
  }
  return days * coinsPerDay;
}
