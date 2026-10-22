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
  static const _min = 50000.0;
  static const _max = 500000.0;
  static const _step = 10000.0;

  late double _value = _clampTarget(widget.user.dailyBudgetTarget);
  var _saving = false;

  static double _clampTarget(double v) => v.clamp(_min, _max);

  bool get _dirty => _value != widget.user.dailyBudgetTarget;

  @override
  void didUpdateWidget(_TargetCard old) {
    super.didUpdateWidget(old);
    if (old.user.dailyBudgetTarget != widget.user.dailyBudgetTarget) {
      _value = _clampTarget(widget.user.dailyBudgetTarget);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(repositoryProvider).setDailyBudget(_value);
      messenger.showSnackBar(
        SnackBar(content: Text('Target harian: ${formatRupiah(_value)}')),
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
            'Target hemat harian',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          Text(
            formatRupiah(_value),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          Slider(
            value: _value,
            min: _min,
            max: _max,
            divisions: ((_max - _min) / _step).round(),
            label: formatShort(_value),
            onChanged: (v) => setState(() => _value = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rp ${formatShort(_min)}', style: _rangeStyle),
              Text('Rp ${formatShort(_max)}', style: _rangeStyle),
            ],
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
                    '≤ ${formatRupiah(_value * happyThreshold)}.',
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

  static const _rangeStyle = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
}
