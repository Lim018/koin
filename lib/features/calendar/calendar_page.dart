import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/budget/budget.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../ui/cozy.dart';
import '../shell/home_shell.dart';

/// Cells for a Monday-first month grid: leading `null`s, then each day.
List<DateTime?> monthGrid(DateTime month) {
  final first = DateTime(month.year, month.month);
  final days = DateUtils.getDaysInMonth(month.year, month.month);
  return [
    for (var i = 1; i < first.weekday; i++) null,
    for (var d = 1; d <= days; d++) DateTime(month.year, month.month, d),
  ];
}

/// "Monthly Diary": pocket-planner grid with under/over-budget dots.
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _selected = dateOnly(DateTime.now());

  void _shiftMonth(int delta) => setState(() {
    _month = DateTime(_month.year, _month.month + delta);
    final today = ref.read(todayProvider);
    _selected = today.year == _month.year && today.month == _month.month
        ? today
        : _month;
  });

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final txs = ref.watch(transactionsProvider(monthRange(_month)));
    final user = ref.watch(userStateProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, navBarClearance),
        children: [
          PageHeader(
            context: DateFormat('MMMM yyyy', 'id_ID').format(_month),
            title: 'Kalender',
            actions: [
              _RoundButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Bulan sebelumnya',
                onPressed: () => _shiftMonth(-1),
              ),
              _RoundButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Bulan berikutnya',
                onPressed: () => _shiftMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          switch ((txs, user)) {
            (AsyncData(value: final t), AsyncData(value: final u)) => _Body(
              month: _month,
              today: today,
              selected: _selected,
              totals: dailyTotals(t),
              dailyBudget: u.dailyBudgetTarget,
              coins: u.savedCoins,
              onSelect: (d) => setState(() => _selected = d),
            ),
            (AsyncError(:final error), _) ||
            (_, AsyncError(:final error)) => ErrorText(error),
            _ => const SizedBox(
              height: 360,
              child: Center(child: CircularProgressIndicator()),
            ),
          },
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.month,
    required this.today,
    required this.selected,
    required this.totals,
    required this.dailyBudget,
    required this.coins,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime today;
  final DateTime selected;
  final Map<DateTime, double> totals;
  final double dailyBudget;
  final int coins;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final overDays = totals.values.where((v) => v > dailyBudget).length;
    final underDays = totals.length - overDays;

    return Column(
      children: [
        CozyCard(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: Column(
            children: [
              Row(
                children: [
                  for (final d in const [
                    'Sen',
                    'Sel',
                    'Rab',
                    'Kam',
                    'Jum',
                    'Sab',
                    'Min',
                  ])
                    Expanded(
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                // Not a page-level scroll view: no safe-area padding.
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 44 / 46,
                children: [
                  for (final day in monthGrid(month))
                    day == null
                        ? const SizedBox.shrink()
                        : _DayCell(
                            day: day,
                            total: totals[day],
                            dailyBudget: dailyBudget,
                            isFuture: day.isAfter(today),
                            isSelected: day == selected,
                            onTap: () => onSelect(day),
                          ),
                ],
              ),
              const Divider(height: 16, color: AppColors.track),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _Legend(
                    color: AppColors.sageSoft,
                    label: 'Di bawah target · $underDays hari',
                  ),
                  _Legend(
                    color: AppColors.sunsetSoft,
                    label: 'Lewat target · $overDays hari',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SelectedDay(
          day: selected,
          isToday: selected == today,
          total: totals[selected],
          dailyBudget: dailyBudget,
        ),
        const SizedBox(height: 12),
        _MonthSummary(
          month: month,
          today: today,
          total: totals.values.fold(0, (a, b) => a + b),
          dailyBudget: dailyBudget,
          coins: coins,
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.total,
    required this.dailyBudget,
    required this.isFuture,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime day;
  final double? total;
  final double dailyBudget;
  final bool isFuture;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = this.total;
    final over = total != null && total > dailyBudget;
    final dot = total == null
        ? Colors.transparent
        : over
        ? AppColors.sunsetSoft
        : AppColors.sageSoft;

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${day.day} ${DateFormat.MMMM('id_ID').format(day)}, '
          '${total == null ? 'belum ada catatan' : '${formatRupiah(total)}, ${over ? 'lewat target' : 'di bawah target'}'}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(1),
          decoration: isSelected
              ? BoxDecoration(
                  color: AppColors.sageLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.sage, width: 1.5),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isFuture
                      ? const Color(0xFFB3A698)
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textOnChip),
        ),
      ],
    );
  }
}

class _SelectedDay extends StatelessWidget {
  const _SelectedDay({
    required this.day,
    required this.isToday,
    required this.total,
    required this.dailyBudget,
  });

  final DateTime day;
  final bool isToday;
  final double? total;
  final double dailyBudget;

  @override
  Widget build(BuildContext context) {
    final spent = total ?? 0;
    final over = spent > dailyBudget;
    final status = total == null
        ? 'Belum ada catatan'
        : over
        ? 'Lewat target ${formatRupiah(spent - dailyBudget)}'
        : 'Hemat ${formatRupiah(dailyBudget - spent)} dari target';

    return CozyCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: over ? AppColors.sunsetLight : AppColors.sageLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: over ? AppColors.sunsetInk : AppColors.sageDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, d MMMM', 'id_ID').format(day) +
                      (isToday ? ' · Hari ini' : ''),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: over ? AppColors.sunsetInk : AppColors.sageDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatRupiah(spent),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({
    required this.month,
    required this.today,
    required this.total,
    required this.dailyBudget,
    required this.coins,
  });

  final DateTime month;
  final DateTime today;
  final double total;
  final double dailyBudget;
  final int coins;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final budget = dailyBudget * daysInMonth;
    final range = monthRange(month);
    final isCurrent = !today.isBefore(range.start) && today.isBefore(range.end);
    final elapsed = isCurrent
        ? today.day
        : (today.isBefore(range.start) ? 0 : daysInMonth);
    final ratio = budget > 0 ? total / budget : 0.0;
    final over = total > budget;

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
                    const Text(
                      'Total Pengeluaran Bulan Ini',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatRupiah(total),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(label: over ? 'Lewat budget' : 'Aman', over: over),
            ],
          ),
          const SizedBox(height: 14),
          BudgetBar(value: ratio),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${(ratio * 100).round()}% dari budget ${formatRupiah(budget)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (isCurrent)
                Text(
                  '${daysInMonth - today.day} hari lagi',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Rata-rata / hari',
                  value: formatRupiah(elapsed > 0 ? total / elapsed : 0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Stat(label: 'Koin terkumpul', value: '$coins koin'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: AppColors.textPrimary),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.card,
        side: const BorderSide(color: AppColors.cardBorder),
        fixedSize: const Size(40, 40),
      ),
    );
  }
}
