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
}

const _androidProvider = 'com.lim018.koin.KokoWidgetProvider';

/// Pushes today's totals and Koko's mood to the Android home widget.
///
/// Never throws: a widget refresh failing must not fail the save that
/// triggered it.
Future<void> syncHomeWidget(KoinRepository repo) async {
  if (!Platform.isAndroid) return;
  try {
    final now = DateTime.now();
    final s = await repo.todaySnapshot();
    final mood = moodFor(spent: s.spent, budget: s.budget);
    await HomeWidget.saveWidgetData<String>(
      WidgetKeys.date,
      DateFormat('yyyy-MM-dd').format(now),
    );
    await HomeWidget.saveWidgetData<int>(WidgetKeys.spent, s.spent.round());
    await HomeWidget.saveWidgetData<int>(WidgetKeys.budget, s.budget.round());
    await HomeWidget.saveWidgetData<String>(WidgetKeys.mood, mood.name);
    await HomeWidget.updateWidget(qualifiedAndroidName: _androidProvider);
  } catch (e, st) {
    debugPrint('Home widget sync failed: $e\n$st');
  }
}
