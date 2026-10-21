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
import '../../ui/koko_sprite.dart';
import '../settings/settings_page.dart';
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
    final text = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, navBarClearance),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM', 'id_ID').format(today),
                      style: text.bodySmall,
                    ),
                    Text('Halo lagi', style: text.headlineMedium),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Otomatisasi',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
                ),
                icon: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.textPrimary,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.card,
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
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
          const SizedBox(height: 24),
          _DiaryHeader(total: todaySummary.valueOrNull?.spent),
          const SizedBox(height: 10),
          transactions.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => ErrorText(e),
            data: (txs) => _DiaryList(transactions: txs),
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
            'Total ${formatRupiah(total!)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
      ],
    );
  }
}

/// Today's entries; swipe left to delete (with undo).
class _DiaryList extends ConsumerStatefulWidget {
  const _DiaryList({required this.transactions});

  final List<Transaction> transactions;

  @override
  ConsumerState<_DiaryList> createState() => _DiaryListState();
}

class _DiaryListState extends ConsumerState<_DiaryList> {
  /// Hidden immediately on swipe: Dismissible requires the row to leave the
  /// tree synchronously, before the Isar stream re-emits.
  final _removed = <int>{};

  Future<void> _delete(Transaction t) async {
    setState(() => _removed.add(t.id));
    final repo = ref.read(repositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repo.deleteTransaction(t.id);
    } catch (e) {
      if (mounted) setState(() => _removed.remove(t.id));
      messenger.showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text('${formatRupiah(t.amount)} dihapus'),
        action: SnackBarAction(
          label: 'URUNGKAN',
          onPressed: () => repo.addTransaction(
            amount: t.amount,
            category: t.category,
            walletSource: t.walletSource,
            timestamp: t.timestamp,
            isAutoLogged: t.isAutoLogged,
            note: t.note,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txs = [
      for (final t in widget.transactions)
        if (!_removed.contains(t.id)) t,
    ];
    if (txs.isEmpty) return const _EmptyDiary();
    return CozyCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (final (i, t) in txs.indexed) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: AppColors.track,
              ),
            _DiaryRow(transaction: t, onDismissed: () => _delete(t)),
          ],
        ],
      ),
    );
  }
}

class _DiaryRow extends StatelessWidget {
  const _DiaryRow({required this.transaction, required this.onDismissed});

  final Transaction transaction;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final category = ExpenseCategory.fromLabel(t.category);
    final subtitle = [
      t.category,
      t.walletSource,
      if (t.isAutoLogged) 'Otomatis',
    ].join(' · ');

    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.sunsetLight,
        child: const Icon(Icons.delete_outline, color: AppColors.sunsetInk),
      ),
      onDismissed: (_) => onDismissed(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                DateFormat.Hm().format(t.timestamp),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: category.tint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(category.emoji, style: const TextStyle(fontSize: 17)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.note ?? t.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '−${formatRupiah(t.amount)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDiary extends StatelessWidget {
  const _EmptyDiary();

  @override
  Widget build(BuildContext context) {
    return const CozyCard(
      child: Text(
        'Belum ada catatan hari ini. Tekan + untuk mencatat pengeluaran.',
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
    );
  }
}
