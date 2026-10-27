import 'package:flutter/material.dart';

import '../core/shop/catalog.dart';
import '../core/theme/app_colors.dart';

/// Flat white card: hairline border, no shadow, radius 20.
class CozyCard extends StatelessWidget {
  const CozyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 20,
    this.color = AppColors.card,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}

/// The flat background behind every screen, in the equipped [habitat]'s
/// colour.
class CozyBackground extends StatelessWidget {
  const CozyBackground({
    super.key,
    required this.child,
    this.habitat = Habitat.kamar,
  });

  final Widget child;
  final Habitat habitat;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: habitat.canvas,
      child: child,
    );
  }
}

/// Rounded progress bar (styled by the theme); turns terracotta once
/// [value] passes 1.
class BudgetBar extends StatelessWidget {
  const BudgetBar({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: value.clamp(0, 1),
      color: value > 1 ? AppColors.sunsetSoft : AppColors.sageSoft,
    );
  }
}

class ErrorText extends StatelessWidget {
  const ErrorText(this.error, {super.key});

  final Object error;

  @override
  Widget build(BuildContext context) => Text(
    'Gagal memuat data: $error',
    style: const TextStyle(color: AppColors.sunsetInk),
  );
}

/// Small rounded status pill (e.g. "Aman", "Lewat Rp 150.000").
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.over});

  final String label;
  final bool over;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: over ? AppColors.sunsetLight : AppColors.sageLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: over ? AppColors.sunsetInk : AppColors.sageDark,
        ),
      ),
    );
  }
}

/// Top of every tab: small context line, the tab's name, optional actions.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.context,
    required this.title,
    this.actions = const [],
  });

  /// e.g. today's date or the month being shown.
  final String context;
  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(this.context, style: text.bodySmall),
              Text(title, style: text.headlineMedium),
            ],
          ),
        ),
        for (final (i, a) in actions.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          a,
        ],
      ],
    );
  }
}

/// Rounded bottom sheet with a drag handle and [title] over [child]; scrolls
/// and lifts above the keyboard.
Future<T?> showCozySheet<T>(
  BuildContext context, {
  required String title,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
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
            child,
          ],
        ),
      ),
    ),
  );
}
