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
/// money in/out, and today's diary.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final todaySummary = ref.watch(todaySummaryProvider);
    final weekSummary = ref.watch(weekSummaryProvider);
    final transactions = ref.watch(transactionsProvider(dayRange(today)));
    final month = ref.watch(transactionsProvider(monthRange(today)));

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          navBarClearance + writeButtonClearance,
        ),
        children: [
          PageHeader(
            context: DateFormat('EEEE, d MMMM', 'id_ID').format(today),
            title: 'Beranda',
            actions: [
              _CoinChip(
                coins: ref.watch(userStateProvider).valueOrNull?.savedCoins,
              ),
            ],
          ),
          const SizedBox(height: 20),
          switch ((todaySummary, weekSummary)) {
            (AsyncData(value: final d), AsyncData(value: final w)) => Column(
              children: [
                _MascotCard(today: d),
                const SizedBox(height: 16),
                _WeeklyBudgetCard(week: w, today: today),
              ],
            ),
            (AsyncError(:final error), _) ||
            (_, AsyncError(:final error)) => ErrorText(error),
            _ => const SizedBox(
              height: 420,
              child: Center(child: CircularProgressIndicator()),
            ),
          },
          if (month case AsyncData(value: final m)) ...[
            const SizedBox(height: 16),
            _MonthFlow(income: incomeOf(m), spent: totalOf(m)),
          ],
          const SizedBox(height: 28),
          _DiaryHeader(total: todaySummary.valueOrNull?.spent),
          const SizedBox(height: 12),
          transactions.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => ErrorText(e),
            data: (txs) => DiaryList(
              transactions: txs,
              emptyText:
                  'Belum ada catatan hari ini. Tekan ✏️ untuk mencatat '
                  'pengeluaran atau pemasukan.',
            ),
          ),
        ],
      ),
    );
  }
}

/// Koko's room plus today's mood and spending.
class _MascotCard extends ConsumerWidget {
  const _MascotCard({required this.today});

  final BudgetSummary today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final mood = today.mood;
    return CozyCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KokoRoom(
            mood: mood,
            look: ref.watch(lookProvider),
            bubble: _bubbleText(mood),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
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
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatRupiah(week.spent),
              style: text.headlineLarge?.copyWith(
                color: over ? AppColors.sunsetInk : null,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('dari ${formatRupiah(week.budget)}', style: text.bodySmall),
          const SizedBox(height: 16),
          BudgetBar(value: week.budget > 0 ? week.spent / week.budget : 0),
          const SizedBox(height: 12),
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
    final text = Theme.of(context).textTheme;
    final net = income - spent;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FlowCard(
                label: 'Pemasukan',
                value: '+${formatRupiah(income)}',
                icon: Icons.south_west_rounded,
                color: AppColors.sageDark,
                tint: AppColors.sageLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FlowCard(
                label: 'Pengeluaran',
                value: '−${formatRupiah(spent)}',
                icon: Icons.north_east_rounded,
                color: AppColors.sunsetInk,
                tint: AppColors.sunsetLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(child: Text('Selisih bulan ini', style: text.bodySmall)),
              Text(
                '${net < 0 ? '−' : '+'}${formatRupiah(net.abs())}',
                style: text.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: net < 0 ? AppColors.sunsetInk : AppColors.sageDark,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlowCard extends StatelessWidget {
  const _FlowCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.tint,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return CozyCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(label, style: text.labelMedium),
          Text('bulan ini', style: text.bodySmall?.copyWith(fontSize: 11)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: text.titleLarge?.copyWith(color: color)),
          ),
        ],
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
