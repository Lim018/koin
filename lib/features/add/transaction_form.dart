import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/categories.dart';
import '../../core/detected_payment.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';

/// Amount + category (+ wallet and note unless [compact]) entry form, shared
/// by the in-app sheet and the home-screen quick-add pop-up.
class TransactionForm extends ConsumerStatefulWidget {
  const TransactionForm({
    super.key,
    required this.onSaved,
    this.compact = false,
    this.initial,
  });

  /// Pre-fill from an auto-read notification ([UBAH]); saved as auto-logged.
  final DetectedPayment? initial;

  /// Called after the transaction is written.
  final ValueChanged<double> onSaved;

  /// Quick-add layout: only the first four categories, no wallet or note.
  final bool compact;

  @override
  ConsumerState<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<TransactionForm> {
  late final _amount = TextEditingController(
    text: widget.initial == null ? '' : formatThousands(widget.initial!.amount),
  );
  final _note = TextEditingController();
  late var _category = widget.initial?.category ?? ExpenseCategory.makan;
  late var _wallet = widget.initial?.wallet ?? walletSources.first;
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
      await ref
          .read(repositoryProvider)
          .addTransaction(
            amount: value,
            category: _category.label,
            walletSource: _wallet,
            timestamp: widget.initial?.timestamp,
            isAutoLogged: widget.initial != null,
            note: note.isEmpty ? null : note,
          );
      widget.onSaved(value);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final canSave = (_value ?? 0) > 0 && !_saving;
    // Compact shows four chips, plus the pre-filled one if it is not among them.
    final categories = widget.compact
        ? ExpenseCategory.values.where(
            (c) => c.index < 4 || c == widget.initial?.category,
          )
        : ExpenseCategory.values;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _amount,
          autofocus: true,
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
          Text('Sumber dana', style: text.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final w in walletSources)
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
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              hintText: 'mis. Nasi padang',
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

Future<void> showAddTransactionSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
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
            Text(
              'Catat pengeluaran',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TransactionForm(
              onSaved: (value) {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('${formatRupiah(value)} tercatat')),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
