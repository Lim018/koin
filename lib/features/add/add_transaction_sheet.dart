import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/categories.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';

Future<void> showAddTransactionSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const AddTransactionSheet(),
  );
}

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  var _category = ExpenseCategory.makan;
  var _wallet = walletSources.first;
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
            note: note.isEmpty ? null : note,
          );
      if (mounted) Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text('${formatRupiah(value)} tercatat')),
      );
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

    return Padding(
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
            Text('Catat pengeluaran', style: text.titleMedium),
            const SizedBox(height: 16),
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
                  borderSide: const BorderSide(
                    color: AppColors.sage,
                    width: 1.5,
                  ),
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
                for (final c in ExpenseCategory.values)
                  ChoiceChip(
                    label: Text('${c.emoji} ${c.label}'),
                    selected: c == _category,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
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
            const SizedBox(height: 20),
            FilledButton(
              onPressed: canSave ? _save : null,
              child: Text(_saving ? 'Menyimpan…' : 'SIMPAN'),
            ),
          ],
        ),
      ),
    );
  }
}
