import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/budget/budget.dart';
import '../../core/db/user_state.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../ui/cozy.dart';
import '../shop/equipped_koko.dart';

/// Daily budget editor; Koko's mood and the coin reward are measured
/// against this target.
class TargetCard extends ConsumerWidget {
  const TargetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(userStateProvider)) {
      AsyncData(:final value) => _TargetCard(user: value),
      AsyncError(:final error) => ErrorText(error),
      _ => const SizedBox(height: 120),
    };
  }
}

class _TargetCard extends ConsumerStatefulWidget {
  const _TargetCard({required this.user});

  final UserState user;

  @override
  ConsumerState<_TargetCard> createState() => _TargetCardState();
}

class _TargetCardState extends ConsumerState<_TargetCard> {
  late final _input = TextEditingController(
    text: formatThousands(widget.user.dailyBudgetTarget),
  );
  var _saving = false;

  double? get _value => parseRupiah(_input.text);

  bool get _dirty {
    final v = _value;
    return v != null && v > 0 && v != widget.user.dailyBudgetTarget;
  }

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_TargetCard old) {
    super.didUpdateWidget(old);
    if (old.user.dailyBudgetTarget != widget.user.dailyBudgetTarget) {
      _input.text = formatThousands(widget.user.dailyBudgetTarget);
    }
  }

  Future<void> _save() async {
    final value = _value;
    if (value == null || !_dirty || _saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(repositoryProvider).setDailyBudget(value);
      messenger.showSnackBar(
        SnackBar(content: Text('Target harian: ${formatRupiah(value)}')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CozyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Target pengeluaran harian',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _input,
            keyboardType: TextInputType.number,
            inputFormatters: const [RupiahInputFormatter()],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            decoration: const InputDecoration(
              prefixText: 'Rp ',
              hintText: '0',
              helperText: 'Batas belanja per hari',
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.sageLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const EquippedKoko(width: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Koko tetap senang selama belanja harianmu '
                    '≤ ${formatRupiah((_value ?? 0) * happyThreshold)}.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.sageDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _dirty && !_saving ? _save : null,
            child: Text(_saving ? 'Menyimpan…' : 'Simpan target'),
          ),
        ],
      ),
    );
  }
}
