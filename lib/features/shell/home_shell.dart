import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../ui/cozy.dart';
import '../add/add_transaction_sheet.dart';
import '../calendar/calendar_page.dart';
import '../dashboard/dashboard_page.dart';
import '../insight/insight_page.dart';

/// Main app frame: the four tabs plus the floating glass nav bar with the
/// central "catat" button.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _index = 0;

  static const _pages = [DashboardPage(), CalendarPage(), InsightPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: CozyBackground(
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: _GlassNavBar(
          index: _index,
          onSelect: (i) => setState(() => _index = i),
          onAdd: () => showAddTransactionSheet(context),
        ),
      ),
    );
  }
}

/// Bottom padding pages need so content clears the floating nav bar.
const navBarClearance = 104.0;

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({
    required this.index,
    required this.onSelect,
    required this.onAdd,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _tab(0, Icons.home_rounded, 'Beranda'),
              _tab(1, Icons.calendar_month_rounded, 'Kalender'),
              _AddButton(onPressed: onAdd),
              _tab(2, Icons.bar_chart_rounded, 'Insight'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(int i, IconData icon, String label) {
    final selected = i == index;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onSelect(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.sageLight : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? AppColors.sageDark : AppColors.textOnChip,
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.sageDark,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Catat pengeluaran',
      child: Material(
        color: AppColors.sage,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const SizedBox(
            width: 50,
            height: 50,
            child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
