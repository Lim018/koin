import 'package:flutter/material.dart';

import '../../core/budget/budget.dart';
import '../../core/shop/catalog.dart';
import '../../core/theme/app_colors.dart';
import '../../ui/koko_sprite.dart';

/// The cozy pixel room from the design: wall, window, checker floor and the
/// pet, coloured by [look]'s habitat.
class KokoRoom extends StatelessWidget {
  const KokoRoom({
    super.key,
    required this.mood,
    required this.look,
    this.bubble,
    this.height = designHeight,
  });

  final KokoMood mood;
  final Look look;

  /// Speech bubble text, top right.
  final String? bubble;

  /// The room scales its contents to this height ([designHeight] = 1:1).
  final double height;

  static const designHeight = 210.0;
  static const _floorHeight = 70.0;

  @override
  Widget build(BuildContext context) {
    final habitat = look.habitat;
    final bubble = this.bubble;
    final scale = height / designHeight;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: height,
        color: habitat.wall,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _floorHeight * scale,
              child: CustomPaint(painter: _CheckerFloor(habitat.floor)),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: _floorHeight * scale,
              height: 6 * scale,
              child: ColoredBox(color: habitat.skirting),
            ),
            Positioned(
              left: 20 * scale,
              top: 20 * scale,
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topLeft,
                child: _Window(habitat.window),
              ),
            ),
            if (bubble != null)
              Positioned(
                right: 14 * scale,
                top: 18 * scale,
                child: Transform.scale(
                  // Text stays readable on short rooms.
                  scale: scale.clamp(0.8, 1),
                  alignment: Alignment.topRight,
                  child: _SpeechBubble(text: bubble),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 24 * scale,
              child: Center(
                child: KokoSprite(
                  mood: mood,
                  width: 100 * scale,
                  hop: true,
                  pet: look.pet,
                  accessory: look.accessory,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckerFloor extends CustomPainter {
  const _CheckerFloor(this.colors);

  final (Color, Color) colors;

  static const _tile = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final (light, darkColor) = colors;
    canvas.drawRect(Offset.zero & size, Paint()..color = light);
    final dark = Paint()..color = darkColor;
    for (var y = 0.0; y < size.height; y += _tile) {
      for (var x = 0.0; x < size.width; x += _tile) {
        final odd = ((x / _tile).round() + (y / _tile).round()).isOdd;
        if (odd) canvas.drawRect(Rect.fromLTWH(x, y, _tile, _tile), dark);
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerFloor old) => old.colors != colors;
}

class _Window extends StatelessWidget {
  const _Window(this.sky);

  final List<Color> sky;

  @override
  Widget build(BuildContext context) {
    const frame = Color(0xFFFFFFFF);
    return Container(
      width: 80,
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: frame, width: 4),
        boxShadow: const [BoxShadow(color: Color(0x14503723), spreadRadius: 1)],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.75, 1],
          colors: sky,
        ),
      ),
      child: const Stack(
        children: [
          Center(
            child: SizedBox(
              width: 4,
              height: double.infinity,
              child: ColoredBox(color: frame),
            ),
          ),
          Center(
            child: SizedBox(
              height: 4,
              width: double.infinity,
              child: ColoredBox(color: frame),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
