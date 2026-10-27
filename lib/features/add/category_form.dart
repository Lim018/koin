import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/transaction.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../ui/cozy.dart';

/// Adds a [kind] category; completes with its label (null when dismissed).
Future<String?> showCategorySheet(
  BuildContext context, {
  required TransactionKind kind,
}) => showCozySheet<String>(
  context,
  title: kind == TransactionKind.income
      ? 'Kategori pemasukan baru'
      : 'Kategori pengeluaran baru',
  child: _CategoryForm(kind: kind),
);

const _emojis = [
  '🍜',
  '🍱',
  '🍕',
  '🥤',
  '🧋',
  '🍰',
  '🛒',
  '👕',
  '👟',
  '💄',
  '🏠',
  '💡',
  '💧',
  '📶',
  '📱',
  '💻',
  '🎮',
  '🎬',
  '🎵',
  '📚',
  '🎓',
  '✏️',
  '🏥',
  '💊',
  '🏋️',
  '⚽',
  '✈️',
  '⛽',
  '🚌',
  '🏍️',
  '🅿️',
  '🐱',
  '🌱',
  '🎁',
  '💝',
  '🙏',
  '💰',
  '💳',
  '📈',
  '🧾',
];

class _CategoryForm extends ConsumerStatefulWidget {
  const _CategoryForm({required this.kind});

  final TransactionKind kind;

  @override
  ConsumerState<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<_CategoryForm> {
  final _name = TextEditingController();
  final _customEmoji = TextEditingController();
  var _emoji = _emojis.first;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _customEmoji.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final c = await ref
          .read(repositoryProvider)
          .addCategory(label: _name.text, emoji: _emoji, kind: widget.kind);
      navigator.pop(c.label);
      messenger.showSnackBar(
        SnackBar(content: Text('Kategori ${c.emoji} ${c.label} ditambahkan')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      final message = switch (e) {
        ArgumentError(name: 'label', message: 'sudah dipakai') =>
          'Nama itu sudah dipakai kategori lain',
        _ => 'Gagal menyimpan: $e',
      };
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final canSave = _name.text.trim().isNotEmpty && !_busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.sageLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(_emoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _name,
                autofocus: true,
                maxLength: 20,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama kategori',
                  hintText: 'mis. Kuliah, Internet',
                  counterText: '',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Emoji', style: text.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final e in _emojis)
              Semantics(
                button: true,
                selected: e == _emoji,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _emoji = e),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: e == _emoji ? AppColors.sageLight : null,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: e == _emoji
                            ? AppColors.sage
                            : AppColors.chipBorder,
                      ),
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 20)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _customEmoji,
          decoration: const InputDecoration(
            labelText: 'Atau ketik emoji lain',
            hintText: '😺',
          ),
          onChanged: (v) {
            final chars = v.trim().characters;
            if (chars.isEmpty) return;
            // Keep only the last typed character (one emoji).
            final last = chars.last;
            setState(() => _emoji = last);
            if (v != last) {
              _customEmoji.value = TextEditingValue(
                text: last,
                selection: TextSelection.collapsed(offset: last.length),
              );
            }
          },
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: canSave ? _save : null,
          child: Text(_busy ? 'Menyimpan…' : 'SIMPAN'),
        ),
      ],
    );
  }
}
