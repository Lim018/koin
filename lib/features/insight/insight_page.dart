import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/budget/budget.dart';
import '../../core/categories.dart';
import '../../core/db/transaction.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../ui/cozy.dart';
import '../shell/home_shell.dart';

enum _Period {
  weekly('Mingguan'),
  monthly('Bulanan'),
  annually('Tahunan'),
  custom('Periode');

  const _Period(this.label);

  final String label;
}

/// Slice colours by rank, largest category first.
const _sliceColors = [
  Color(0xFFF2735F),
  Color(0xFFF79A5B),
  Color(0xFFF6C344),
  Color(0xFFE9DC4A),
  Color(0xFFB5D65A),
  Color(0xFF7FB77E),
  Color(0xFF6FA8C9),
  Color(0xFFA78BC9),
];
const _restColor = Color(0xFFC9BFB4);

/// Spending (or income) per category as a pie chart, for a week, month, year
/// or a picked period.
class InsightView extends ConsumerStatefulWidget {
  const InsightView({super.key, required this.viewSwitch});

  /// Kalender/Grafik toggle shown under the header (see StatsPage).
  final Widget viewSwitch;

  @override
  ConsumerState<InsightView> createState() => _InsightViewState();
}

class _InsightViewState extends ConsumerState<InsightView> {
  var _period = _Period.monthly;
  var _kind = TransactionKind.expense;

  /// A day inside the shown week/month/year.
  late DateTime _anchor = dateOnly(DateTime.now());

  /// The picked range for [_Period.custom]; defaults to this month.
  late DateRange _custom = monthRange(ref.read(todayProvider));

  DateRange get _range => switch (_period) {
    _Period.weekly => weekRange(_anchor),
    _Period.monthly => monthRange(_anchor),
    _Period.annually => yearRange(_anchor),
    _Period.custom => _custom,
  };

  /// Moves one week/month/year, keeping the day (clamped to the month's
  /// length) so switching period stays near the same date.
  void _shift(int delta) => setState(() {
    final a = _anchor;
    if (_period == _Period.weekly) {
      _anchor = DateTime(a.year, a.month, a.day + 7 * delta);
      return;
    }
    final (year, month) = switch (_period) {
      _Period.monthly => (a.year, a.month + delta),
      _Period.annually => (a.year + delta, a.month),
      _ => (a.year, a.month),
    };
    final first = DateTime(year, month);
    final last = DateUtils.getDaysInMonth(first.year, first.month);
    _anchor = DateTime(first.year, first.month, math.min(a.day, last));
  });

  Future<void> _pickRange() async {
    final today = ref.read(todayProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year + 1, 12, 31),
      initialDateRange: DateTimeRange(
        start: _custom.start,
        end: _custom.end.subtract(const Duration(days: 1)),
      ),
      helpText: 'Pilih periode',
      saveText: 'PAKAI',
    );
    if (picked == null) return;
    setState(() {
      _custom = (
        start: dateOnly(picked.start),
        end: DateTime(picked.end.year, picked.end.month, picked.end.day + 1),
      );
    });
  }

  String _label(DateRange r) {
    final last = DateTime(r.end.year, r.end.month, r.end.day - 1);
    return switch (_period) {
      _Period.monthly => DateFormat('MMMM yyyy', 'id_ID').format(r.start),
      _Period.annually => '${r.start.year}',
      _ =>
        '${DateFormat('d MMM', 'id_ID').format(r.start)} – '
            '${DateFormat('d MMM yyyy', 'id_ID').format(last)}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final range = _range;
    final txs = ref.watch(transactionsProvider(range));
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? Categories();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, navBarClearance),
        children: [
          PageHeader(
            context: 'Per kategori',
            title: 'Statistik',
            actions: [
              PopupMenuButton<_Period>(
                tooltip: 'Pilih rentang',
                initialValue: _period,
                onSelected: (p) {
                  setState(() => _period = p);
                  if (p == _Period.custom) _pickRange();
                },
                itemBuilder: (context) => [
                  for (final p in _Period.values)
                    PopupMenuItem(value: p, child: Text(p.label)),
                ],
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _period.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(Icons.expand_more_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          widget.viewSwitch,
          const SizedBox(height: 12),
          _RangeBar(
            label: _label(range),
            onPrevious: _period == _Period.custom ? null : () => _shift(-1),
            onNext: _period == _Period.custom ? null : () => _shift(1),
            onPick: _period == _Period.custom ? _pickRange : null,
          ),
          const SizedBox(height: 12),
          SegmentedButton<TransactionKind>(
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.zero,
            segments: const [
              ButtonSegment(
                value: TransactionKind.expense,
                label: Text('Pengeluaran'),
              ),
              ButtonSegment(
                value: TransactionKind.income,
                label: Text('Pemasukan'),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          const SizedBox(height: 12),
          switch (txs) {
            AsyncData(value: final t) => _Breakdown(
              kind: _kind,
              slices: _slices([
                for (final x in t)
                  if (x.kind == _kind) x,
              ], categories),
            ),
            AsyncError(:final error) => ErrorText(error),
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

typedef _Slice = ({TxCategory category, double amount, Color color});

/// Totals per category, largest first, coloured by rank.
List<_Slice> _slices(List<Transaction> txs, Categories categories) {
  final byLabel = <String, ({TxCategory category, double amount})>{};
  for (final t in txs) {
    final c = categories.of(t);
    final prev = byLabel[c.label];
    byLabel[c.label] = (category: c, amount: (prev?.amount ?? 0) + t.amount);
  }
  final sorted = byLabel.values.toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
  return [
    for (final (i, s) in sorted.indexed)
      (
        category: s.category,
        amount: s.amount,
        color: i < _sliceColors.length ? _sliceColors[i] : _restColor,
      ),
  ];
}

class _RangeBar extends StatelessWidget {
  const _RangeBar({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  /// Opens the range picker ([_Period.custom] only).
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final pick = onPick;
    return CozyCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          if (pick == null)
            IconButton(
              tooltip: 'Sebelumnya',
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
          Expanded(
            child: pick == null
                ? Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : TextButton.icon(
                    onPressed: pick,
                    icon: const Icon(Icons.date_range_rounded),
                    label: Text(label),
                  ),
          ),
          if (pick == null)
            IconButton(
              tooltip: 'Berikutnya',
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
        ],
      ),
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.kind, required this.slices});

  final TransactionKind kind;
  final List<_Slice> slices;

  @override
  Widget build(BuildContext context) {
    final income = kind == TransactionKind.income;
    final total = slices.fold(0.0, (a, s) => a + s.amount);
    if (total <= 0) {
      return CozyCard(
        child: SizedBox(
          height: 160,
          child: Center(
            child: Text(
              income
                  ? 'Belum ada pemasukan di rentang ini'
                  : 'Belum ada pengeluaran di rentang ini',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        CozyCard(
          child: Center(
            child: SizedBox.square(
              dimension: 220,
              child: Semantics(
                label: [
                  for (final s in slices)
                    '${s.category.label} '
                        '${(s.amount / total * 100).round()} persen',
                ].join(', '),
                excludeSemantics: true,
                child: CustomPaint(
                  painter: _PiePainter(slices: slices, total: total),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          income ? 'Pemasukan' : 'Pengeluaran',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          formatShort(total),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        CozyCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              for (final (i, s) in slices.indexed) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.track,
                  ),
                _SliceRow(slice: s, share: s.amount / total),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SliceRow extends StatelessWidget {
  const _SliceRow({required this.slice, required this.share});

  final _Slice slice;
  final double share;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: slice.color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${(share * 100).round()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(slice.category.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              slice.category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            formatRupiah(slice.amount),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Donut chart: one arc per slice, clockwise from 12 o'clock.
class _PiePainter extends CustomPainter {
  _PiePainter({required this.slices, required this.total});

  final List<_Slice> slices;
  final double total;

  static const _thickness = 44.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - _thickness / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _thickness;
    // Thin gaps between slices, unless one slice is the whole circle.
    final gap = slices.length > 1 ? 0.02 : 0.0;
    var start = -math.pi / 2;
    for (final s in slices) {
      final sweep = s.amount / total * 2 * math.pi;
      paint.color = s.color;
      canvas.drawArc(
        rect,
        start + gap / 2,
        math.max(sweep - gap, 0.001),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_PiePainter old) =>
      old.slices != slices || old.total != total;
}
