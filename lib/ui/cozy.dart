import 'package:flutter/material.dart';

import '../core/shop/catalog.dart';
import '../core/theme/app_colors.dart';

/// White card with a 1px border and a very soft warm shadow.
class CozyCard extends StatelessWidget {
  const CozyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(0, 10),
            blurRadius: 28,
            spreadRadius: -16,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// The gradient behind every screen, in the equipped [habitat]'s colours.
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.6, 1],
          colors: habitat.background,
        ),
      ),
      child: child,
    );
  }
}

/// Rounded progress bar; turns sunset orange once [value] passes 1.
class BudgetBar extends StatelessWidget {
  const BudgetBar({super.key, required this.value, this.height = 8});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        backgroundColor: AppColors.track,
        color: value > 1 ? AppColors.sunsetSoft : AppColors.sageSoft,
      ),
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
