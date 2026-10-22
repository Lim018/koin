import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/budget/budget.dart';
import '../../core/db/repository.dart';
import '../../core/providers.dart';
import '../../core/shop/catalog.dart';
import '../../core/theme/app_colors.dart';
import '../../ui/cozy.dart';
import '../../ui/koko_sprite.dart';
import '../room/koko_room.dart';
import 'coins.dart';

Future<void> openShop(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => const ShopPage()));

const _tabs = {
  ShopSlot.pet: 'Pet',
  ShopSlot.accessory: 'Aksesoris',
  ShopSlot.habitat: 'Habitat',
};

/// Toko Koko: spend coins on pets, accessories and habitats. Tapping an item
/// tries it on in the room preview before buying.
class ShopPage extends ConsumerStatefulWidget {
  const ShopPage({super.key});

  @override
  ConsumerState<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends ConsumerState<ShopPage> {
  var _tab = ShopSlot.pet;
  ShopItem? _selected;

  List<ShopItem> get _items => switch (_tab) {
    ShopSlot.pet => PetSpecies.values,
    ShopSlot.accessory => Accessory.values,
    ShopSlot.habitat => Habitat.values,
  };

  static Look _tryOn(Look look, ShopItem? item) => switch (item) {
    final PetSpecies p => (
      pet: p,
      accessory: look.accessory,
      habitat: look.habitat,
    ),
    final Accessory a => (pet: look.pet, accessory: a, habitat: look.habitat),
    final Habitat h => (pet: look.pet, accessory: look.accessory, habitat: h),
    _ => look,
  };

  Future<void> _act(Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } on StateError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _buy(ShopItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Beli ${item.label}?'),
        content: Text(
          'Harganya ${item.price} koin. Langsung dipakai setelah '
          'dibeli.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Beli'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _act(
      () => ref.read(repositoryProvider).buyItem(item),
      '${item.label} dibeli dan dipakai',
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userStateProvider).valueOrNull;
    final look = ref.watch(lookProvider);
    final coins = user?.savedCoins ?? 0;
    final preview = _tryOn(look, _selected);
    bool owns(ShopItem i) =>
        user == null ? i.price == 0 : KoinRepository.owns(user, i);
    bool wearing(ShopItem i) =>
        i == look.pet || i == look.accessory || i == look.habitat;

    return Scaffold(
      body: CozyBackground(
        habitat: preview.habitat,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 20, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Kembali',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: PageHeader(
                      context: 'Tukar koinmu',
                      title: 'Toko Koko',
                      actions: [
                        _CoinPill(
                          coins: coins,
                          onTap: () => showCoinInfo(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: CozyCard(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      KokoRoom(
                        mood: KokoMood.happy,
                        look: preview,
                        height: 190,
                      ),
                      _ActionBar(
                        item: _selected,
                        coins: coins,
                        owned: _selected != null && owns(_selected!),
                        wearing: _selected != null && wearing(_selected!),
                        onBuy: _buy,
                        onEquip: (i) => _act(
                          () => ref.read(repositoryProvider).equipItem(i),
                          '${i.label} dipakai',
                        ),
                        onRemove: () => _act(
                          ref.read(repositoryProvider).removeAccessory,
                          'Aksesoris dilepas',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: SegmentedButton<ShopSlot>(
                  showSelectedIcon: false,
                  expandedInsets: EdgeInsets.zero,
                  segments: [
                    for (final MapEntry(:key, :value) in _tabs.entries)
                      ButtonSegment(value: key, label: Text(value)),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (s) => setState(() {
                    _tab = s.first;
                    _selected = null;
                  }),
                ),
              ),
              if (_tab == ShopSlot.habitat)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 10, 8, 0),
                  child: Text(
                    'Habitat mengganti warna kamar, latar, dan menu aplikasi.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.78,
                  children: [
                    for (final item in _items)
                      _ItemTile(
                        item: item,
                        look: look,
                        selected: item == _selected,
                        owned: owns(item),
                        wearing: wearing(item),
                        onTap: () => setState(
                          () => _selected = item == _selected ? null : item,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoinPill extends StatelessWidget {
  const _CoinPill({required this.coins, required this.onTap});

  final int coins;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Saldo $coins koin, cara dapat koin',
      button: true,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.fromLTRB(10, 0, 8, 0),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomPaint(size: Size(16, 16), painter: PixelCoin()),
              const SizedBox(width: 6),
              Text(
                '$coins',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Under the preview: what is being tried on and what can be done with it.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.item,
    required this.coins,
    required this.owned,
    required this.wearing,
    required this.onBuy,
    required this.onEquip,
    required this.onRemove,
  });

  final ShopItem? item;
  final int coins;
  final bool owned;
  final bool wearing;
  final ValueChanged<ShopItem> onBuy;
  final ValueChanged<ShopItem> onEquip;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final item = this.item;
    if (item == null) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(8, 14, 8, 6),
        child: Text(
          'Ketuk item di bawah untuk mencobanya di kamar Koko.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }
    final short = item.price - coins;
    final (String status, Widget button) = switch ((owned, wearing)) {
      (true, true) when item is Accessory => (
        'Sedang dipakai',
        OutlinedButton(onPressed: onRemove, child: const Text('Lepas')),
      ),
      (true, true) => (
        'Sedang dipakai',
        const FilledButton(onPressed: null, child: Text('Dipakai')),
      ),
      (true, false) => (
        'Sudah kamu punya',
        FilledButton(
          onPressed: () => onEquip(item),
          child: const Text('Pakai'),
        ),
      ),
      _ when short > 0 => (
        'Kurang $short koin lagi',
        FilledButton(onPressed: null, child: Text('${item.price} koin')),
      ),
      _ => (
        '${item.price} koin',
        FilledButton(onPressed: () => onBuy(item), child: const Text('Beli')),
      ),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: short > 0 && !owned
                        ? AppColors.sunsetInk
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // The theme makes buttons full width; keep this one compact.
          SizedBox(width: 112, child: button),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.look,
    required this.selected,
    required this.owned,
    required this.wearing,
    required this.onTap,
  });

  final ShopItem item;

  /// Equipped look, so accessories show on the user's own pet.
  final Look look;
  final bool selected;
  final bool owned;
  final bool wearing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preview = switch (item) {
      final PetSpecies p => KokoSprite(mood: KokoMood.happy, width: 56, pet: p),
      final Accessory a => KokoSprite(
        mood: KokoMood.happy,
        width: 56,
        pet: look.pet,
        accessory: a,
      ),
      final Habitat h => _HabitatSwatch(h),
      _ => const SizedBox.shrink(),
    };
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? AppColors.sage : AppColors.cardBorder,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
          child: Column(
            children: [
              Expanded(child: Center(child: preview)),
              const SizedBox(height: 6),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              _Badge(price: item.price, owned: owned, wearing: wearing),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.price,
    required this.owned,
    required this.wearing,
  });

  final int price;
  final bool owned;
  final bool wearing;

  @override
  Widget build(BuildContext context) {
    if (owned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: wearing ? AppColors.sageLight : AppColors.track,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          wearing ? 'Dipakai' : 'Punya',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: wearing ? AppColors.sageDark : AppColors.textSecondary,
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CustomPaint(size: Size(12, 12), painter: PixelCoin()),
        const SizedBox(width: 4),
        Text(
          '$price',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.coinDark,
          ),
        ),
      ],
    );
  }
}

class _HabitatSwatch extends StatelessWidget {
  const _HabitatSwatch(this.habitat);

  final Habitat habitat;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 64,
        height: 52,
        child: Column(
          children: [
            Expanded(
              child: ColoredBox(
                color: habitat.wall,
                child: Center(
                  child: Container(
                    width: 22,
                    height: 18,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: habitat.window,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < 6; i++)
                    Expanded(
                      child: ColoredBox(
                        color: i.isEven ? habitat.floor.$1 : habitat.floor.$2,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
