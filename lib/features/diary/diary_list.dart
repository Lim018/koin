import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/categories.dart';
import '../../core/db/transaction.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../ui/cozy.dart';
import '../add/transaction_form.dart';

/// A day's entries: tap to edit, swipe left to delete (with undo) unless
/// [readOnly]. Shows [emptyText] in a card when there are none, or nothing if
/// it is null.
class DiaryList extends ConsumerStatefulWidget {
  const DiaryList({
    super.key,
    required this.transactions,
    this.emptyText,
    this.readOnly = false,
  });

  final List<Transaction> transactions;
  final String? emptyText;
  final bool readOnly;

  @override
  ConsumerState<DiaryList> createState() => _DiaryListState();
}

class _DiaryListState extends ConsumerState<DiaryList> {
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
            kind: t.kind,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? Categories();
    final txs = [
      for (final t in widget.transactions)
        if (!_removed.contains(t.id)) t,
    ];
    if (txs.isEmpty) {
      final empty = widget.emptyText;
      return empty == null ? const SizedBox.shrink() : _EmptyDiary(empty);
    }
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
            _DiaryRow(
              transaction: t,
              category: categories.of(t),
              onTap: widget.readOnly
                  ? null
                  : () => showTransactionSheet(context, editing: t),
              onDismissed: widget.readOnly ? null : () => _delete(t),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiaryRow extends StatelessWidget {
  const _DiaryRow({
    required this.transaction,
    required this.category,
    required this.onTap,
    required this.onDismissed,
  });

  final Transaction transaction;
  final TxCategory category;

  /// Both null when the list is read-only.
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final subtitle = [
      t.category,
      t.walletSource,
      if (t.isAutoLogged) 'Otomatis',
    ].join(' · ');

    return Dismissible(
      key: ValueKey(t.id),
      direction: onDismissed == null
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.sunsetLight,
        child: const Icon(Icons.delete_outline, color: AppColors.sunsetInk),
      ),
      onDismissed: (_) => onDismissed?.call(),
      child: InkWell(
        onTap: onTap,
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
                child: Text(
                  category.emoji,
                  style: const TextStyle(fontSize: 17),
                ),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${t.isIncome ? '+' : '−'}${formatRupiah(t.amount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: t.isIncome
                      ? AppColors.sageDark
                      : AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDiary extends StatelessWidget {
  const _EmptyDiary(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return CozyCard(
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
    );
  }
}
