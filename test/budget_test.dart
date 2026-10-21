import 'package:flutter_test/flutter_test.dart';
import 'package:koin/core/budget/budget.dart';
import 'package:koin/core/db/transaction.dart';
import 'package:koin/core/format.dart';

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

  test('formatRupiah uses Indonesian separators', () {
    expect(formatRupiah(250000), 'Rp 250.000');
  });
}
