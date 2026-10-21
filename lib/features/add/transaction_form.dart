import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/budget/budget.dart';
import '../../core/categories.dart';
import '../../core/db/transaction.dart';
import '../../core/detected_payment.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';

/// Amount + category (+ kind, wallet and note unless [compact]) entry form,
/// shared by the in-app sheet and the home-screen quick-add pop-up.
class TransactionForm extends ConsumerStatefulWidget {
  const TransactionForm({
    super.key,
    required this.onSaved,
    this.compact = false,
    this.initial,
    this.editing,
    this.day,
  });

  /// Pre-fill from an auto-read notification ([UBAH]); saved as auto-logged.
  final DetectedPayment? initial;

  /// Existing entry to change; keeps its id, time and auto-logged flag.
  final Transaction? editing;

  /// Records a new entry on this (past) day instead of now.
  final DateTime? day;

  /// Called after the transaction is written.
  final ValueChanged<double> onSaved;

  /// Quick-add layout: expenses only, the first four categories, no wallet
  /// or note.
  final bool compact;

  @override
  ConsumerState<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<TransactionForm> {
  late final _amount = TextEditingController(
    text: switch (widget.editing?.amount ?? widget.initial?.amount) {
      final a? => formatThousands(a),
      null => '',
    },
  );
  late final _note = TextEditingController(text: widget.editing?.note);
  late var _kind = widget.editing?.kind ?? TransactionKind.expense;
  late TxCategory _category = switch (widget.editing) {
    final e? => TxCategory.of(e),
    null => widget.initial?.category ?? ExpenseCategory.makan,
  };
  late var _wallet =
      widget.editing?.walletSource ??
      widget.initial?.wallet ??
      walletSources.first;

  /// Keeps an unusual stored wallet (e.g. from an old entry) selectable.
  late final _wallets = {...walletSources, _wallet}.toList();
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  double? get _value => parseRupiah(_amount.text);

  Future<void> _save() async {
    final value = _value;
    if (value == null || value <= 0 || _saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final note = _note.text.trim();
      final repo = ref.read(repositoryProvider);
      if (widget.editing case final e?) {
        await repo.updateTransaction(
          Transaction()
            ..id = e.id
            ..timestamp = e.timestamp
            ..isAutoLogged = e.isAutoLogged
            ..kind = _kind
            ..amount = value
            ..category = _category.label
            ..walletSource = _wallet
            ..note = note.isEmpty ? null : note,
        );
      } else {
        await repo.addTransaction(
          amount: value,
          category: _category.label,
          walletSource: _wallet,
          timestamp: widget.initial?.timestamp ?? _timestampOn(widget.day),
          isAutoLogged: widget.initial != null,
          note: note.isEmpty ? null : note,
          kind: _kind,
        );
      }
      widget.onSaved(value);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    }
  }

  /// Now's time of day on [day] (null for today), so entries keep order.
  static DateTime? _timestampOn(DateTime? day) {
    final now = DateTime.now();
    if (day == null || dateOnly(day) == dateOnly(now)) return null;
    return DateTime(day.year, day.month, day.day, now.hour, now.minute);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final canSave = (_value ?? 0) > 0 && !_saving;
    // Compact shows four chips, plus the pre-filled one if it is not among them.
    final Iterable<TxCategory> categories = widget.compact
        ? ExpenseCategory.values.where(
            (c) => c.index < 4 || c == widget.initial?.category,
          )
        : TxCategory.forKind(_kind);
    final income = _kind == TransactionKind.income;
    // A detected payment is always money going out.
    final canSwitchKind = !widget.compact && widget.initial == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canSwitchKind) ...[
          SegmentedButton<TransactionKind>(
            showSelectedIcon: false,
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
            onSelectionChanged: (s) => setState(() {
              _kind = s.first;
              _category = TxCategory.forKind(_kind).first;
            }),
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _amount,
          // Editing opens on the whole entry, not straight into the keyboard.
          autofocus: widget.editing == null,
          keyboardType: TextInputType.number,
          inputFormatters: const [RupiahInputFormatter()],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            labelText: 'Jumlah',
            hintText: '0',
            prefixText: 'Rp ',
            prefixStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.sageLight.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.sage),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.sage, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Kategori', style: text.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in categories)
              ChoiceChip(
                label: Text('${c.emoji} ${c.label}'),
                selected: c == _category,
                showCheckmark: false,
                onSelected: (_) => setState(() => _category = c),
              ),
          ],
        ),
        if (!widget.compact) ...[
          const SizedBox(height: 16),
          Text(income ? 'Masuk ke' : 'Sumber dana', style: text.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final w in _wallets)
                ChoiceChip(
                  label: Text(w),
                  selected: w == _wallet,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _wallet = w),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            maxLength: 60,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Catatan (opsional)',
              hintText: income ? 'mis. Gaji Oktober' : 'mis. Nasi padang',
              counterText: '',
            ),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: canSave ? _save : null,
          child: Text(_saving ? 'Menyimpan…' : 'SIMPAN'),
        ),
      ],
    );
  }
}

/// The in-app entry sheet: a new entry (today, or on [day]) or, with
/// [editing], changes to an existing one.
Future<void> showTransactionSheet(
  BuildContext context, {
  Transaction? editing,
  DateTime? day,
}) {
  final title = switch ((editing, day)) {
    (_?, _) => 'Ubah catatan',
    (null, final d?) when dateOnly(d) != dateOnly(DateTime.now()) =>
      'Catat untuk ${DateFormat('d MMMM', 'id_ID').format(d)}',
    _ => 'Catat transaksi',
  };
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    // Android 15+ is edge-to-edge: keep the sheet below the status bar.
    useSafeArea: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
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
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TransactionForm(
              editing: editing,
              day: day,
              onSaved: (value) {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      editing == null
                          ? '${formatRupiah(value)} tercatat'
                          : 'Perubahan disimpan',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
