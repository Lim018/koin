import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/budget/budget.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../ui/cozy.dart';
import '../../ui/koko_sprite.dart';
import '../diary/diary_list.dart';
import '../room/koko_room.dart';
import '../shop/coins.dart';
import '../shop/shop_page.dart';
import '../shell/home_shell.dart';

/// Beranda, top to bottom: Koko's room, this week's budget, this month's
/// money in/out, and today's diary — all on one screen. Koko's room and the
/// diary share the height the fixed cards leave (the diary scrolls inside
/// its share). Phones too short for that scroll the whole page instead.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  /// Below this content height the room would get too small to read.
  static const _minFitHeight = 540.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final todaySummary = ref.watch(todaySummaryProvider);
    final weekSummary = ref.watch(weekSummaryProvider);
    final transactions = ref.watch(transactionsProvider(dayRange(today)));
    final month = ref.watch(transactionsProvider(monthRange(today)));

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, navBarClearance - 8),
        child: LayoutBuilder(
          builder: (context, c) {
            final fits = c.maxHeight >= _minFitHeight;
            final diary = transactions.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => ErrorText(e),
              data: (txs) => DiaryList(
                transactions: txs,
                emptyText:
                    'Belum ada catatan hari ini. Tekan ✏️ untuk '
                    'mencatat pengeluaran atau pemasukan.',
              ),
            );
            // Room to scroll the last entry out from under the pencil.
            const pencilGap = EdgeInsets.only(bottom: writeButtonClearance);

            final column = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  context: DateFormat('EEEE, d MMMM', 'id_ID').format(today),
                  title: 'Beranda',
                  actions: [
                    _CoinChip(
                      coins: ref
                          .watch(userStateProvider)
                          .valueOrNull
                          ?.savedCoins,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...switch ((todaySummary, weekSummary)) {
                  (AsyncData(value: final d), AsyncData(value: final w)) => [
                    fits
                        ? Flexible(child: _MascotCard(today: d))
                        : _MascotCard(today: d, roomHeight: 120),
                    const SizedBox(height: 10),
                    _WeeklyBudgetCard(week: w, today: today),
                  ],
                  (AsyncError(:final error), _) ||
                  (_, AsyncError(:final error)) => [ErrorText(error)],
                  _ => [
                    const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                },
                if (month case AsyncData(value: final m)) ...[
                  const SizedBox(height: 10),
                  _MonthFlow(income: incomeOf(m), spent: totalOf(m)),
                ],
                const SizedBox(height: 14),
                _DiaryHeader(total: todaySummary.valueOrNull?.spent),
                const SizedBox(height: 8),
                if (fits)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: pencilGap,
                      child: diary,
                    ),
                  )
                else
                  Padding(padding: pencilGap, child: diary),
              ],
            );
            return fits ? column : SingleChildScrollView(child: column);
          },
        ),
      ),
    );
  }
}

/// Koko's room plus today's mood and spending. The room is [roomHeight]
/// tall, or takes the height the card is given (up to
/// [KokoRoom.designHeight]) when that is null.
class _MascotCard extends ConsumerWidget {
  const _MascotCard({required this.today, this.roomHeight});

  final BudgetSummary today;
  final double? roomHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final mood = today.mood;
    Widget room(double height) => KokoRoom(
      mood: mood,
      look: ref.watch(lookProvider),
      bubble: _bubbleText(mood),
      height: height,
    );
    return CozyCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          switch (roomHeight) {
            final h? => room(h),
            null => Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: KokoRoom.designHeight,
                ),
                child: LayoutBuilder(
                  builder: (context, c) => room(c.maxHeight),
                ),
              ),
            ),
          },
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 2),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'Mood Koko  ', style: text.bodySmall),
                        TextSpan(
                          text: moodLabel(mood),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: mood == KokoMood.happy
                                ? AppColors.sageDark
                                : AppColors.sunsetInk,
                          ),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('Hari ini ', style: text.bodySmall),
                Text(
                  formatRupiah(today.spent),
                  style: text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _bubbleText(KokoMood mood) => switch (mood) {
  KokoMood.happy => 'Hari ini aman,\nmantap!',
  KokoMood.neutral => 'Hampir batas nih,\npelan-pelan ya.',
  KokoMood.grumpy => 'Udah lewat\ntarget hari ini!',
};

/// This week's spending against 7 × the daily target.
class _WeeklyBudgetCard extends StatelessWidget {
  const _WeeklyBudgetCard({required this.week, required this.today});

  final BudgetSummary week;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final over = isOverBudget(spent: week.spent, budget: week.budget);
    final left = week.budget - week.spent;
    // The week ends on Sunday; today still counts.
    final daysLeft = 8 - today.weekday;
    return CozyCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Budget minggu ini', style: text.labelMedium),
              ),
              StatusPill(label: over ? 'Lewat' : 'Aman', over: over),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: formatRupiah(week.spent),
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: over ? AppColors.sunsetInk : null,
                    ),
                  ),
                  TextSpan(
                    text: '  dari ${formatRupiah(week.budget)}',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          BudgetBar(value: week.budget > 0 ? week.spent / week.budget : 0),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  over
                      ? 'Lewat ${formatRupiah(-left)}'
                      : 'Sisa ${formatRupiah(left)}',
                  style: text.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: over ? AppColors.sunsetInk : AppColors.sageDark,
                  ),
                ),
              ),
              Text(
                daysLeft == 1 ? 'Hari terakhir' : '$daysLeft hari lagi',
                style: text.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// This month's money in vs. out (income never affects Koko's budget).
class _MonthFlow extends StatelessWidget {
  const _MonthFlow({required this.income, required this.spent});

  final double income;
  final double spent;

  @override
  Widget build(BuildContext context) {
    final net = income - spent;
    return CozyCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _FlowCell(
              label: 'Pemasukan bulan ini',
              value: '+${formatRupiah(income)}',
              color: AppColors.sageDark,
            ),
            const VerticalDivider(width: 1, color: AppColors.track),
            _FlowCell(
              label: 'Pengeluaran bulan ini',
              value: '−${formatRupiah(spent)}',
              color: AppColors.sunsetInk,
            ),
            const VerticalDivider(width: 1, color: AppColors.track),
            _FlowCell(
              label: 'Selisih bulan ini',
              value: '${net < 0 ? '−' : '+'}${formatRupiah(net.abs())}',
              color: net < 0 ? AppColors.sunsetInk : AppColors.sageDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowCell extends StatelessWidget {
  const _FlowCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 2,
              style: text.bodySmall?.copyWith(fontSize: 11, height: 1.2),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: text.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiaryHeader extends StatelessWidget {
  const _DiaryHeader({required this.total});

  final double? total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Diary hari ini',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (total != null)
          Text(
            'Keluar ${formatRupiah(total!)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
      ],
    );
  }
}

/// Coin balance pill from the room design (pixel coin + count); opens
/// Toko Koko.
class _CoinChip extends StatelessWidget {
  const _CoinChip({required this.coins});

  final int? coins;

  @override
  Widget build(BuildContext context) {
    final coins = this.coins;
    if (coins == null) return const SizedBox.shrink();
    return Semantics(
      label: 'Saldo $coins koin',
      button: true,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => openShop(context),
        child: Container(
          height: 36,
          padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomPaint(size: Size(16, 16), painter: PixelCoin()),
              const SizedBox(width: 6),
              Text(
                '$coins',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
