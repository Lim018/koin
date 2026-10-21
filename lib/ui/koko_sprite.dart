import 'package:flutter/material.dart';

import '../core/budget/budget.dart';

/// Pixel-art Koko, ported from the SVG sprites in docs/standalone.html.
/// Drawn on a 20×18 grid (viewBox -1 -4 20 18) so pixels stay crisp.
class KokoSprite extends StatefulWidget {
  const KokoSprite({
    super.key,
    required this.mood,
    this.width = 112,
    this.hop = false,
  });

  final KokoMood mood;
  final double width;

  /// Two-frame idle bounce, as in the room design.
  final bool hop;

  @override
  State<KokoSprite> createState() => _KokoSpriteState();
}

class _KokoSpriteState extends State<KokoSprite>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  @override
  void initState() {
    super.initState();
    if (widget.hop) _controller.repeat();
  }

  @override
  void didUpdateWidget(KokoSprite old) {
    super.didUpdateWidget(old);
    if (widget.hop && !_controller.isAnimating) _controller.repeat();
    if (!widget.hop) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.width * _gridH / _gridW;
    return Semantics(
      label: 'Koko ${moodLabel(widget.mood).toLowerCase()}',
      image: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.translate(
          // steps(2): up during the second half of each cycle.
          offset: Offset(0, _controller.value >= 0.5 ? -widget.width / 28 : 0),
          child: child,
        ),
        child: CustomPaint(
          size: Size(widget.width, height),
          painter: _KokoPainter(widget.mood),
        ),
      ),
    );
  }
}

String moodLabel(KokoMood mood) => switch (mood) {
  KokoMood.happy => 'Senang',
  KokoMood.neutral => 'Khawatir',
  KokoMood.grumpy => 'Kesal',
};

const _gridW = 20.0;
const _gridH = 18.0;
const _originX = -1.0;
const _originY = -4.0;

typedef _Px = (double x, double y, double w, double h);

const _fur = Color(0xFFF7C59F);
const _ink = Color(0xFF4A3628);
const _blush = Color(0xFFF2A98A);
const _angry = Color(0xFFE8875A);

const List<_Px> _body = [
  (4, 1, 1, 1),
  (11, 1, 1, 1),
  (4, 2, 2, 1),
  (10, 2, 2, 1),
  (3, 3, 10, 1),
  (2, 4, 12, 7),
  (3, 11, 10, 1),
  (5, 12, 6, 1),
];

const List<_Px> _outline = [
  (4, 0, 1, 1),
  (11, 0, 1, 1),
  (3, 1, 1, 2),
  (5, 1, 1, 1),
  (10, 1, 1, 1),
  (12, 1, 1, 2),
  (6, 2, 4, 1),
  (2, 3, 1, 1),
  (13, 3, 1, 1),
  (1, 4, 1, 7),
  (14, 4, 1, 7),
  (2, 11, 1, 1),
  (13, 11, 1, 1),
  (3, 12, 2, 1),
  (11, 12, 2, 1),
  (4, 13, 8, 1),
];

const _cheeks = <_Px>[(2, 8, 2, 1), (12, 8, 2, 1)];

const Map<KokoMood, List<_Px>> _faces = {
  KokoMood.happy: [
    (3, 7, 1, 1), (4, 6, 1, 1), (5, 7, 1, 1), // ^ eye
    (10, 7, 1, 1), (11, 6, 1, 1), (12, 7, 1, 1), // ^ eye
    (5, 9, 1, 1), (10, 9, 1, 1), (6, 10, 4, 1), // smile
  ],
  KokoMood.neutral: [
    (4, 6, 1, 2), (11, 6, 1, 2), // dot eyes
    (6, 10, 4, 1), // flat mouth
  ],
  KokoMood.grumpy: [
    (3, 5, 2, 1), (5, 6, 1, 1), (11, 5, 2, 1), (10, 6, 1, 1), // brows
    (4, 7, 2, 1), (10, 7, 2, 1), // eyes
    (6, 9, 4, 1), (5, 10, 1, 1), (10, 10, 1, 1), // frown
  ],
};

/// The little "anger" cross floating above Koko's head.
const _angerMark = <_Px>[
  (15, -3, 1, 1),
  (17, -3, 1, 1),
  (16, -2, 1, 1),
  (15, -1, 1, 1),
  (17, -1, 1, 1),
];

class _KokoPainter extends CustomPainter {
  const _KokoPainter(this.mood);

  final KokoMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / _gridW;
    final paint = Paint()..isAntiAlias = false;

    void draw(List<_Px> pixels, Color color) {
      paint.color = color;
      for (final (x, y, w, h) in pixels) {
        canvas.drawRect(
          Rect.fromLTWH(
            (x - _originX) * unit,
            (y - _originY) * unit,
            w * unit,
            h * unit,
          ),
          paint,
        );
      }
    }

    final grumpy = mood == KokoMood.grumpy;
    draw(_body, _fur);
    draw(_outline, _ink);
    draw(_faces[mood]!, _ink);
    draw(_cheeks, grumpy ? _angry : _blush);
    if (grumpy) draw(_angerMark, _angry);
  }

  @override
  bool shouldRepaint(_KokoPainter old) => old.mood != mood;
}
