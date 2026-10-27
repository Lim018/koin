import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import 'budget/budget.dart';
import 'db/repository.dart';

/// Keys shared with android/.../KokoWidgetProvider.kt.
abstract final class WidgetKeys {
  static const date = 'koin_date'; // yyyy-MM-dd the totals belong to
  static const spent = 'koin_spent'; // whole rupiah
  static const budget = 'koin_budget'; // whole rupiah
  static const mood = 'koin_mood'; // KokoMood.name

  /// Calendar widget: yyyy-MM, and that month's spending per day as
  /// comma-separated whole rupiah ('' for days without entries).
  static const calendarMonth = 'koin_cal_month';
  static const calendarTotals = 'koin_cal_totals';
}

const _androidProviders = [
  'com.lim018.koin.KokoWidgetProvider',
  'com.lim018.koin.CalendarWidgetProvider',
];

/// Pushes today's totals, Koko's mood and this month's daily totals to the
/// Android home widgets.
///
/// Never throws: a widget refresh failing must not fail the save that
/// triggered it.
Future<void> syncHomeWidget(KoinRepository repo) async {
  if (!Platform.isAndroid) return;
  try {
    final now = DateTime.now();
    final budget = await repo.dailyBudget();
    final month = monthRange(now);
    final totals = dailyTotals(await repo.transactionsIn(month));
    final spent = totals[dateOnly(now)] ?? 0;
    final mood = moodFor(spent: spent, budget: budget);
    await HomeWidget.saveWidgetData<String>(
      WidgetKeys.date,
      DateFormat('yyyy-MM-dd').format(now),
    );
    await HomeWidget.saveWidgetData<int>(WidgetKeys.spent, spent.round());
    await HomeWidget.saveWidgetData<int>(WidgetKeys.budget, budget.round());
    await HomeWidget.saveWidgetData<String>(WidgetKeys.mood, mood.name);
    await HomeWidget.saveWidgetData<String>(
      WidgetKeys.calendarMonth,
      DateFormat('yyyy-MM').format(now),
    );
    await HomeWidget.saveWidgetData<String>(
      WidgetKeys.calendarTotals,
      [
        for (
          var d = month.start;
          d.isBefore(month.end);
          d = DateTime(d.year, d.month, d.day + 1)
        )
          switch (totals[d]) {
            final t? => '${t.round()}',
            null => '',
          },
      ].join(','),
    );
    for (final provider in _androidProviders) {
      await HomeWidget.updateWidget(qualifiedAndroidName: provider);
    }
  } catch (e, st) {
    debugPrint('Home widget sync failed: $e\n$st');
  }
}
