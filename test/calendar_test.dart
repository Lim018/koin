import 'package:flutter_test/flutter_test.dart';
import 'package:koin/features/calendar/calendar_page.dart';

void main() {
  test('monthGrid pads to Monday and lists every day', () {
    // 1 Oct 2026 is a Thursday → 3 blanks (Sen, Sel, Rab).
    final cells = monthGrid(DateTime(2026, 10));
    expect(cells.take(3), everyElement(isNull));
    expect(cells[3], DateTime(2026, 10, 1));
    expect(cells.last, DateTime(2026, 10, 31));
    expect(cells.length, 3 + 31);
  });

  test('monthGrid handles a month starting on Monday and leap February', () {
    final cells = monthGrid(DateTime(2027, 2)); // 1 Feb 2027 is a Monday.
    expect(cells.first, DateTime(2027, 2, 1));
    expect(cells.length, 28);
    expect(monthGrid(DateTime(2028, 2)).whereType<DateTime>().length, 29);
  });
}
