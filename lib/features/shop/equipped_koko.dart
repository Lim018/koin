import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/budget/budget.dart';
import '../../core/providers.dart';
import '../../ui/koko_sprite.dart';

/// Koko as the user dressed it up in Toko Koko (pet + accessory).
class EquippedKoko extends ConsumerWidget {
  const EquippedKoko({super.key, this.mood = KokoMood.happy, this.width = 112});

  final KokoMood mood;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final look = ref.watch(lookProvider);
    return KokoSprite(
      mood: mood,
      width: width,
      pet: look.pet,
      accessory: look.accessory,
    );
  }
}
