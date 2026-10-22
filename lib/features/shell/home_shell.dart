import 'package:flutter/material.dart';

import '../../core/budget/budget.dart';
import '../../core/theme/app_colors.dart';
import '../../ui/cozy.dart';
import '../../ui/koko_sprite.dart';
import '../accounts/accounts_page.dart';
import '../add/transaction_form.dart';
import '../dashboard/dashboard_page.dart';
import '../settings/settings_page.dart';
import '../stats/stats_page.dart';

/// Main app frame: four tabs (Beranda · Statistik · Bank · Profil) in a
/// floating nav bar, plus the floating "catat" pencil on Beranda.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _index = 0;

  static const _pages = [
    DashboardPage(),
    StatsPage(),
    AccountsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: CozyBackground(
        child: IndexedStack(index: _index, children: _pages),
      ),
      floatingActionButton: _index == 0
          ? _WriteButton(onPressed: () => showTransactionSheet(context))
          : null,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: _NavBar(
          index: _index,
          onSelect: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}

/// Bottom padding pages need so content clears the floating nav bar.
const navBarClearance = 108.0;

/// Extra clearance on Beranda for the floating pencil above the nav bar.
const writeButtonClearance = 80.0;

const _barColor = Color(0xFFFCF1E2);
const _tileColor = Color(0xFFF6E7D3);
const _selectedColor = Color(0xFFFDE2C0);

class _NavBar extends StatelessWidget {
  const _NavBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: _barColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F503723),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _tab(0, const _Emoji('📒'), 'Beranda'),
          _tab(1, const _Emoji('📊'), 'Statistik'),
          _tab(2, const _Emoji('👛'), 'Bank'),
          _tab(3, const KokoSprite(mood: KokoMood.happy, width: 30), 'Profil'),
        ],
      ),
    );
  }

  Widget _tab(int i, Widget icon, String label) {
    final selected = i == index;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelect(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: selected ? _selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.5)
                      : _tileColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: icon,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 10, 0),
                        child: Text(
                          label,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textOnChip,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Emoji extends StatelessWidget {
  const _Emoji(this.emoji);

  final String emoji;

  @override
  Widget build(BuildContext context) =>
      Text(emoji, style: const TextStyle(fontSize: 25, height: 1));
}

class _WriteButton extends StatelessWidget {
  const _WriteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Catat transaksi',
      child: Material(
        color: const Color(0xFFC0525C),
        elevation: 6,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: const SizedBox(
            width: 64,
            height: 64,
            child: Center(
              child: Text('✏️', style: TextStyle(fontSize: 32, height: 1)),
            ),
          ),
        ),
      ),
    );
  }
}
