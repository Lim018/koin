import 'package:flutter_test/flutter_test.dart';
import 'package:koin/core/budget/budget.dart';
import 'package:koin/core/db/transaction.dart';

Transaction tx(DateTime t, double amount) => Transaction()
  ..timestamp = t
  ..amount = amount
  ..category = 'Makan'
  ..walletSource = 'Cash';

void main() {
  group('moodFor', () {
    test('happy up to 80% of budget', () {
      expect(moodFor(spent: 0, budget: 200000), KokoMood.happy);
      expect(moodFor(spent: 160000, budget: 200000), KokoMood.happy);
    });
    test('neutral between 80% and 100%', () {
      expect(moodFor(spent: 160001, budget: 200000), KokoMood.neutral);
      expect(moodFor(spent: 200000, budget: 200000), KokoMood.neutral);
    });
    test('grumpy when over budget', () {
      expect(moodFor(spent: 350000, budget: 200000), KokoMood.grumpy);
    });
    test('zero budget never divides by zero', () {
      expect(moodFor(spent: 0, budget: 0), KokoMood.happy);
      expect(moodFor(spent: 1, budget: 0), KokoMood.grumpy);
    });
  });

  group('ranges', () {
    test('week starts on Monday', () {
      // Wednesday 21 Oct 2026.
      final r = weekRange(DateTime(2026, 10, 21, 13, 5));
      expect(r.start, DateTime(2026, 10, 19));
      expect(r.end, DateTime(2026, 10, 26));
    });
    test('Sunday belongs to the week that started the Monday before', () {
      final r = weekRange(DateTime(2026, 10, 25, 23, 59));
      expect(r.start, DateTime(2026, 10, 19));
    });
    test('day and month ranges roll over year end', () {
      expect(dayRange(DateTime(2026, 12, 31, 9)).end, DateTime(2027, 1, 1));
      expect(monthRange(DateTime(2026, 12, 5)).end, DateTime(2027, 1, 1));
    });
  });

  test('totalOf and dailyTotals group by calendar day', () {
    final txs = [
      tx(DateTime(2026, 10, 21, 7, 30), 20000),
      tx(DateTime(2026, 10, 21, 12, 15), 45000),
      tx(DateTime(2026, 10, 22, 8), 35000),
    ];
    expect(totalOf(txs), 100000);
    expect(dailyTotals(txs), {
      DateTime(2026, 10, 21): 65000,
      DateTime(2026, 10, 22): 35000,
    });
  });

  test('weeklyBudget is 7 × daily (matches design: 200rb → 1,4jt)', () {
    expect(weeklyBudget(200000), 1400000);
  });

  group('coinsEarned', () {
    final totals = {
      DateTime(2026, 10, 18): 150000.0, // under → +50
      DateTime(2026, 10, 19): 200000.0, // exactly on target → +50
      DateTime(2026, 10, 20): 350000.0, // over → 0
      DateTime(2026, 10, 21): 10000.0, // today, not finished → excluded
    };

    test('rewards finished days within budget only', () {
      expect(
        coinsEarned(
          totals: totals,
          dailyBudget: 200000,
          from: DateTime(2026, 10, 1),
          until: DateTime(2026, 10, 21),
        ),
        2 * coinsPerDay,
      );
    });

    test('respects the evaluated window', () {
      expect(
        coinsEarned(
          totals: totals,
          dailyBudget: 200000,
          from: DateTime(2026, 10, 19),
          until: DateTime(2026, 10, 20),
        ),
        coinsPerDay,
      );
    });

    test('days without entries earn nothing', () {
      expect(
        coinsEarned(
          totals: const {},
          dailyBudget: 200000,
          from: DateTime(2026, 10, 1),
          until: DateTime(2026, 10, 21),
        ),
        0,
      );
    });
  });
}
