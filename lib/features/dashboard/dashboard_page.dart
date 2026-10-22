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

/// "Kamar Koko": the mascot's room on top, today's diary below.
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
          const SizedBox(height: 16),
          switch ((todaySummary, weekSummary)) {
            (AsyncData(value: final d), AsyncData(value: final w)) => _RoomCard(
              today: d,
              week: w,
            ),
            (AsyncError(:final error), _) ||
            (_, AsyncError(:final error)) => ErrorText(error),
            _ => const SizedBox(
              height: 320,
              child: Center(child: CircularProgressIndicator()),
            ),
          },
          if (month case AsyncData(value: final m)) ...[
            const SizedBox(height: 12),
            _MonthFlow(income: incomeOf(m), spent: totalOf(m)),
          ],
          const SizedBox(height: 24),
          _DiaryHeader(total: todaySummary.valueOrNull?.spent),
          const SizedBox(height: 10),
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

class _RoomCard extends ConsumerWidget {
  const _RoomCard({required this.today, required this.week});

  final BudgetSummary today;
  final BudgetSummary week;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mood = today.mood;
    final weekOver = isOverBudget(spent: week.spent, budget: week.budget);

    return CozyCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KokoRoom(
            mood: mood,
            look: ref.watch(lookProvider),
            bubble: _bubbleText(mood),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Mood Koko  ',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
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
                    Text(
                      'Hari ini ${formatRupiah(today.spent)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Budget minggu ini',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: formatRupiah(week.spent),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: weekOver ? AppColors.sunsetInk : null,
                            ),
                          ),
                          TextSpan(text: ' / ${formatRupiah(week.budget)}'),
                        ],
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                BudgetBar(
                  value: week.budget > 0 ? week.spent / week.budget : 0,
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

/// This month's money in vs. out (income never affects Koko's budget).
class _MonthFlow extends StatelessWidget {
  const _MonthFlow({required this.income, required this.spent});

  final double income;
  final double spent;

  @override
  Widget build(BuildContext context) {
    final net = income - spent;
    return CozyCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            child: _Flow(
              label: 'Masuk bulan ini',
              value: '+${formatRupiah(income)}',
              color: AppColors.sageDark,
            ),
          ),
          Expanded(
            child: _Flow(
              label: 'Keluar bulan ini',
              value: '−${formatRupiah(spent)}',
              color: AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: _Flow(
              label: 'Selisih',
              value: '${net < 0 ? '−' : '+'}${formatRupiah(net.abs())}',
              color: net < 0 ? AppColors.sunsetInk : AppColors.sageDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _Flow extends StatelessWidget {
  const _Flow({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
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
