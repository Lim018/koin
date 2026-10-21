import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/budget/budget.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../ui/cozy.dart';
import '../shell/home_shell.dart';

enum _Period { week, month }

/// Spending per day vs. the daily target.
class InsightPage extends ConsumerStatefulWidget {
  const InsightPage({super.key});

  @override
  ConsumerState<InsightPage> createState() => _InsightPageState();
}

class _InsightPageState extends ConsumerState<InsightPage> {
  var _period = _Period.week;

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final range = _period == _Period.week
        ? weekRange(today)
        : monthRange(today);
    final txs = ref.watch(transactionsProvider(range));
    final user = ref.watch(userStateProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, navBarClearance),
        children: [
          PageHeader(
            context: DateFormat('MMMM yyyy', 'id_ID').format(today),
            title: 'Insight',
            actions: [
              SegmentedButton<_Period>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: _Period.week, label: Text('Minggu')),
                  ButtonSegment(value: _Period.month, label: Text('Bulan')),
                ],
                selected: {_period},
                onSelectionChanged: (s) => setState(() => _period = s.first),
              ),
            ],
          ),
          const SizedBox(height: 16),
          switch ((txs, user)) {
            (AsyncData(value: final t), AsyncData(value: final u)) =>
              _SpendingCard(
                period: _period,
                range: range,
                today: today,
                totals: dailyTotals(t),
                dailyBudget: u.dailyBudgetTarget,
              ),
            (AsyncError(:final error), _) ||
            (_, AsyncError(:final error)) => ErrorText(error),
            _ => const SizedBox(
              height: 280,
              child: Center(child: CircularProgressIndicator()),
            ),
          },
        ],
      ),
    );
  }
}

class _SpendingCard extends StatelessWidget {
  const _SpendingCard({
    required this.period,
    required this.range,
    required this.today,
    required this.totals,
    required this.dailyBudget,
  });

  final _Period period;
  final DateRange range;
  final DateTime today;
  final Map<DateTime, double> totals;
  final double dailyBudget;

  @override
  Widget build(BuildContext context) {
    final days = [
      for (
        var d = range.start;
        d.isBefore(range.end);
        d = DateTime(d.year, d.month, d.day + 1)
      )
        d,
    ];
    final total = totals.values.fold(0.0, (a, b) => a + b);
    final budget = dailyBudget * days.length;
    final ratio = budget > 0 ? total / budget : 0.0;
    final isWeek = period == _Period.week;

    return CozyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isWeek
                          ? 'Pengeluaran minggu ini'
                          : 'Pengeluaran bulan ini',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      formatRupiah(total),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: '${(ratio * 100).round()}% budget',
                over: ratio > 1,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: _BarChart(
              days: days,
              today: today,
              totals: totals,
              dailyBudget: dailyBudget,
              labelFor: isWeek
                  ? (d) => DateFormat.E('id_ID').format(d)
                  : (d) => (d.day == 1 || d.day % 7 == 0) ? '${d.day}' : '',
              showValues: isWeek,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.days,
    required this.today,
    required this.totals,
    required this.dailyBudget,
    required this.labelFor,
    required this.showValues,
  });

  final List<DateTime> days;
  final DateTime today;
  final Map<DateTime, double> totals;
  final double dailyBudget;
  final String Function(DateTime) labelFor;
  final bool showValues;

  static const _labelHeight = 18.0;
  static const _valueHeight = 16.0;

  @override
  Widget build(BuildContext context) {
    final maxDay = totals.values.fold(0.0, (a, b) => a > b ? a : b);
    final scale = (maxDay > dailyBudget ? maxDay : dailyBudget) * 1.15;

    return LayoutBuilder(
      builder: (context, c) {
        final plot = c.maxHeight - _labelHeight - _valueHeight;
        final targetY = scale > 0 ? plot * dailyBudget / scale : 0.0;

        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: _labelHeight + targetY,
              child: Row(
                children: [
                  const Expanded(child: _DashedLine()),
                  Text(
                    ' Target ${formatShort(dailyBudget)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final d in days)
                  Expanded(
                    child: _Bar(
                      value: totals[d] ?? 0,
                      height: scale > 0 ? plot * (totals[d] ?? 0) / scale : 0,
                      over: (totals[d] ?? 0) > dailyBudget,
                      isFuture: d.isAfter(today),
                      isToday: d == today,
                      label: labelFor(d),
                      showValue: showValues,
                      gap: days.length > 7 ? 1.5 : 6,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.height,
    required this.over,
    required this.isFuture,
    required this.isToday,
    required this.label,
    required this.showValue,
    required this.gap,
  });

  final double value;
  final double height;
  final bool over;
  final bool isFuture;
  final bool isToday;
  final String label;
  final bool showValue;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final color = isFuture
        ? AppColors.track
        : over
        ? AppColors.sunsetSoft
        : AppColors.sageSoft;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: gap / 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: _BarChart._valueHeight,
            child: showValue && value > 0
                ? Text(
                    formatShort(value),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: over
                          ? AppColors.sunsetInk
                          : AppColors.textSecondary,
                    ),
                  )
                : null,
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: isFuture ? 6 : height.clamp(2, double.infinity),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(gap > 2 ? 6 : 2),
            ),
          ),
          SizedBox(
            height: _BarChart._labelHeight,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: isToday
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final count = (c.maxWidth / 8).floor();
        return Row(
          children: [
            for (var i = 0; i < count; i++)
              Container(
                width: 4,
                height: 1,
                margin: const EdgeInsets.only(right: 4),
                color: AppColors.textMuted,
              ),
          ],
        );
      },
    );
  }
}
