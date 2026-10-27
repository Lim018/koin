import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/shop/catalog.dart';
import '../../core/theme/app_colors.dart';
import '../../ui/cozy.dart';
import '../accounts/accounts_page.dart';
import '../add/transaction_form.dart';
import '../dashboard/dashboard_page.dart';
import '../settings/settings_page.dart';
import '../shop/equipped_koko.dart';
import '../stats/stats_page.dart';

/// Main app frame: four tabs (Beranda · Statistik · Bank · Profil) in a
/// floating nav bar, plus the floating "catat" pencil on Beranda.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  var _index = 0;

  static const _pages = [
    DashboardPage(),
    StatsPage(),
    AccountsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final habitat = ref.watch(lookProvider).habitat;
    return Scaffold(
      extendBody: true,
      body: CozyBackground(
        habitat: habitat,
        child: IndexedStack(index: _index, children: _pages),
      ),
      floatingActionButton: _index == 0
          ? _WriteButton(onPressed: () => showTransactionSheet(context))
          : null,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: _NavBar(
          habitat: habitat,
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

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.habitat,
    required this.index,
    required this.onSelect,
  });

  /// Colours the bar (bar, idle tile, selected pill).
  final Habitat habitat;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final (bar, _, _) = habitat.nav;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: bar,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // The selected tab is Flexible: on narrow phones its label
          // truncates instead of overflowing.
          for (final (i, icon, label) in [
            (0, const _Emoji('📒') as Widget, 'Beranda'),
            (1, const _Emoji('📊'), 'Statistik'),
            (2, const _Emoji('👛'), 'Bank'),
            (3, const EquippedKoko(width: 30), 'Profil'),
          ])
            if (i == index)
              Flexible(child: _tab(i, icon, label))
            else
              _tab(i, icon, label),
        ],
      ),
    );
  }

  Widget _tab(int i, Widget icon, String label) {
    final selected = i == index;
    final (_, tile, pill) = habitat.nav;
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
            color: selected ? pill : Colors.transparent,
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
                  color: selected ? Colors.white.withValues(alpha: 0.5) : tile,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: icon,
              ),
              Flexible(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 10, 0),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textOnChip,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
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
        elevation: 2,
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
