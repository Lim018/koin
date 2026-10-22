import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/budget/budget.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';

/// How coins are earned and whether today is on track.
Future<void> showCoinInfo(BuildContext context) {
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
            const CustomPaint(size: Size(28, 28), painter: PixelCoin()),
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
          'Tukar koinmu di Toko Koko dengan pet, aksesoris, dan habitat baru.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// 8×8 pixel-art coin.
class PixelCoin extends CustomPainter {
  const PixelCoin();

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
  bool shouldRepaint(PixelCoin old) => false;
}
