import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/budget/budget.dart';
import 'core/format.dart';
import 'core/providers.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';

class KoinApp extends StatelessWidget {
  const KoinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Koin',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _PlaceholderHome(),
    );
  }
}

/// Temporary screen proving the data layer is wired up; replaced by the
/// Kamar Koko dashboard in Tahap 2.
class _PlaceholderHome extends ConsumerWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(todaySummaryProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: summary.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Gagal memuat data: $e')),
            data: (s) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pengeluaran hari ini', style: text.bodySmall),
                Text(formatRupiah(s.spent), style: text.displaySmall),
                Text(
                  'Target ${formatRupiah(s.budget)} · Mood Koko: '
                  '${_moodLabel(s.mood)}',
                  style: text.bodyMedium?.copyWith(
                    color: s.mood == KokoMood.grumpy
                        ? AppColors.sunset
                        : AppColors.sageDark,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => ref
                      .read(repositoryProvider)
                      .addTransaction(amount: 25000, category: 'Makan'),
                  child: const Text('+ TAMBAH Rp 25.000 (uji)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _moodLabel(KokoMood mood) => switch (mood) {
  KokoMood.happy => 'Senang',
  KokoMood.neutral => 'Netral',
  KokoMood.grumpy => 'Kesal',
};
