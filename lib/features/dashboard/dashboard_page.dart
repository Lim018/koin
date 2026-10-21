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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, navBarClearance),
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
                  'Belum ada catatan hari ini. Tekan + untuk mencatat '
                  'pengeluaran atau pemasukan.',
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.today, required this.week});

  final BudgetSummary today;
  final BudgetSummary week;

  @override
  Widget build(BuildContext context) {
    final mood = today.mood;
    final weekOver = isOverBudget(spent: week.spent, budget: week.budget);

    return CozyCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Room(mood: mood),
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

/// The cozy pixel room from the design: wall, window, checker floor, Koko.
class _Room extends StatelessWidget {
  const _Room({required this.mood});

  final KokoMood mood;

  static const _floorHeight = 70.0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 210,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: AppColors.roomWall)),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _floorHeight,
              child: CustomPaint(painter: _CheckerFloor()),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: _floorHeight,
              height: 6,
              child: ColoredBox(color: Color(0xFFE3CBAE)),
            ),
            const Positioned(left: 20, top: 20, child: _Window()),
            Positioned(
              right: 14,
              top: 18,
              child: _SpeechBubble(text: _bubbleText(mood)),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: KokoSprite(mood: mood, width: 100, hop: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _bubbleText(KokoMood mood) => switch (mood) {
    KokoMood.happy => 'Hari ini aman,\nmantap!',
    KokoMood.neutral => 'Hampir batas nih,\npelan-pelan ya.',
    KokoMood.grumpy => 'Udah lewat\ntarget hari ini!',
  };
}

class _CheckerFloor extends CustomPainter {
  const _CheckerFloor();

  static const _tile = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEEDCC4),
    );
    final dark = Paint()..color = const Color(0xFFE7D2B6);
    for (var y = 0.0; y < size.height; y += _tile) {
      for (var x = 0.0; x < size.width; x += _tile) {
        final odd = ((x / _tile).round() + (y / _tile).round()).isOdd;
        if (odd) canvas.drawRect(Rect.fromLTWH(x, y, _tile, _tile), dark);
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerFloor old) => false;
}

class _Window extends StatelessWidget {
  const _Window();

  @override
  Widget build(BuildContext context) {
    const frame = Color(0xFFFFFFFF);
    return Container(
      width: 80,
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: frame, width: 4),
        boxShadow: const [BoxShadow(color: Color(0xFFEADBC8), spreadRadius: 1)],
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.75, 1],
          colors: [Color(0xFFD7E6E6), Color(0xFFF7DCC2), Color(0xFFF2BE98)],
        ),
      ),
      child: const Stack(
        children: [
          Center(
            child: SizedBox(
              width: 4,
              height: double.infinity,
              child: ColoredBox(color: frame),
            ),
          ),
          Center(
            child: SizedBox(
              height: 4,
              width: double.infinity,
              child: ColoredBox(color: frame),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
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

/// Coin balance pill from the room design (pixel coin + count); tap for
/// how coins are earned.
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
        onTap: () => _showCoinInfo(context, coins),
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
              const CustomPaint(size: Size(16, 16), painter: _PixelCoin()),
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

Future<void> _showCoinInfo(BuildContext context, int coins) {
  return showModalBottomSheet(
    context: context,
    useSafeArea: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => const Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: _CoinInfo(),
    ),
  );
}

/// What coins are for and whether today is on track to earn them.
class _CoinInfo extends ConsumerWidget {
  const _CoinInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(userStateProvider).valueOrNull?.savedCoins ?? 0;
    final today = ref.watch(todaySummaryProvider).valueOrNull;
    final (todayText, onTrack) = switch (today) {
      null => ('', true),
      (spent: 0, budget: _, mood: _) => (
        'Belum ada catatan hari ini. Catat pengeluaranmu supaya hari ini '
            'bisa dihitung.',
        false,
      ),
      final t when isOverBudget(spent: t.spent, budget: t.budget) => (
        'Hari ini sudah lewat target, jadi belum dapat koin. Besok coba '
            'lagi, ya!',
        false,
      ),
      final t => (
        'Hari ini masih aman. Tetap di bawah '
            '${formatRupiah(t.budget)} sampai tengah malam untuk dapat '
            '+$coinsPerDay koin.',
        true,
      ),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.chipBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const CustomPaint(size: Size(28, 28), painter: _PixelCoin()),
            const SizedBox(width: 10),
            Text(
              '$coins koin',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Dapat +$coinsPerDay koin untuk setiap hari yang ada catatannya dan '
          'pengeluarannya tidak lewat target harian. Koin dihitung setelah '
          'hari berakhir.',
          style: TextStyle(fontSize: 14, height: 1.45),
        ),
        if (todayText.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: onTrack ? AppColors.sageLight : AppColors.sunsetLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              todayText,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: onTrack ? AppColors.sageDark : AppColors.sunsetInk,
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        const Text(
          'Segera: tukar koin di Toko Koko untuk menghias kamarnya.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _PixelCoin extends CustomPainter {
  const _PixelCoin();

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 8;
    void px(List<(double, double, double, double)> rects, Color color) {
      final paint = Paint()
        ..color = color
        ..isAntiAlias = false;
      for (final (x, y, w, h) in rects) {
        canvas.drawRect(Rect.fromLTWH(x * u, y * u, w * u, h * u), paint);
      }
    }

    px([(2, 1, 4, 6), (1, 2, 6, 4)], AppColors.coin);
    px([
      (2, 0, 4, 1),
      (1, 1, 1, 1),
      (6, 1, 1, 1),
      (0, 2, 1, 4),
      (7, 2, 1, 4),
      (1, 6, 1, 1),
      (6, 6, 1, 1),
      (2, 7, 4, 1),
    ], AppColors.coinDark);
    px([(3, 2, 1, 3)], const Color(0xFFFFF3C4));
  }

  @override
  bool shouldRepaint(_PixelCoin old) => false;
}
