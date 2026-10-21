import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../ui/cozy.dart';
import '../add/transaction_form.dart';
import '../calendar/calendar_page.dart';
import '../dashboard/dashboard_page.dart';
import '../insight/insight_page.dart';
import '../settings/settings_page.dart';

/// Main app frame: the four tabs plus the floating glass nav bar with the
/// central "catat" button (Beranda · Kalender · + · Insight · Atur).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _index = 0;

  static const _pages = [
    DashboardPage(),
    CalendarPage(),
    InsightPage(),
    SettingsPage(),
  ];

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
          onAdd: () => showTransactionSheet(context),
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
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              _tab(0, Icons.home_rounded, 'Beranda'),
              _tab(1, Icons.calendar_month_rounded, 'Kalender'),
              Expanded(
                child: Center(child: _AddButton(onPressed: onAdd)),
              ),
              _tab(2, Icons.bar_chart_rounded, 'Insight'),
              _tab(3, Icons.tune_rounded, 'Atur'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(int i, IconData icon, String label) {
    final selected = i == index;
    final color = selected ? AppColors.sageDark : AppColors.textOnChip;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onSelect(i),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 28,
                decoration: BoxDecoration(
                  color: selected ? AppColors.sageLight : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
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
