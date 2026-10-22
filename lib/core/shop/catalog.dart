/// Everything sold in Toko Koko: pets, accessories and habitats.
///
/// Pixel art uses Koko's 20×18 grid (x -1…18, y -4…13); the head spans
/// x 1…14, y 3…13 and its ears sit above y 3.
library;

import 'package:flutter/painting.dart';

/// One pixel-art rectangle on the sprite grid: `(x, y, width, height)`.
typedef Px = (double x, double y, double w, double h);

/// Pixels of one colour.
typedef PxLayer = (Color color, List<Px> pixels);

enum ShopSlot { pet, accessory, habitat }

/// Something that can be bought and worn/used. Stored by [key].
abstract interface class ShopItem {
  ShopSlot get slot;

  /// Stable enum name, stored in [UserState].
  String get id;
  String get label;

  /// 0 = free and owned from the start.
  int get price;
}

extension ShopItemKey on ShopItem {
  /// e.g. `pet:kelinci`; what [UserState.ownedItems] holds.
  String get key => '${slot.name}:$id';
}

enum EarShape {
  pointed(
    fill: [(4, 1, 1, 1), (11, 1, 1, 1), (4, 2, 2, 1), (10, 2, 2, 1)],
    outline: [
      (4, 0, 1, 1),
      (11, 0, 1, 1),
      (3, 1, 1, 2),
      (5, 1, 1, 1),
      (10, 1, 1, 1),
      (12, 1, 1, 2),
      (6, 2, 4, 1),
    ],
  ),
  round(
    fill: [(3, 1, 2, 2), (11, 1, 2, 2)],
    outline: [
      (3, 0, 2, 1),
      (11, 0, 2, 1),
      (2, 1, 1, 2),
      (5, 1, 1, 1),
      (10, 1, 1, 1),
      (13, 1, 1, 2),
      (5, 2, 6, 1),
    ],
  ),
  long(
    fill: [(4, -2, 2, 5), (10, -2, 2, 5)],
    outline: [
      (4, -3, 2, 1),
      (10, -3, 2, 1),
      (3, -2, 1, 5),
      (6, -2, 1, 4),
      (9, -2, 1, 4),
      (12, -2, 1, 5),
      (6, 2, 4, 1),
    ],
    inner: [(5, -1, 1, 3), (10, -1, 1, 3)],
  ),
  bumps(
    fill: [(3, 1, 3, 2), (10, 1, 3, 2)],
    outline: [
      (3, 0, 3, 1),
      (10, 0, 3, 1),
      (2, 1, 1, 2),
      (6, 1, 1, 1),
      (9, 1, 1, 1),
      (13, 1, 1, 2),
      (6, 2, 4, 1),
    ],
  );

  const EarShape({
    required this.fill,
    required this.outline,
    this.inner = const [],
  });

  final List<Px> fill;
  final List<Px> outline;

  /// Drawn in the blush colour.
  final List<Px> inner;
}

enum PetSpecies implements ShopItem {
  kucing('Koko si Kucing', 0, Color(0xFFF7C59F), EarShape.pointed),
  kucingAbu('Kucing Abu', 120, Color(0xFFCFCAD6), EarShape.pointed),
  beruang(
    'Beruang',
    200,
    Color(0xFFC8925E),
    EarShape.round,
    marks: [
      (Color(0xFFEBC9A3), [(5, 9, 6, 3)]),
    ],
  ),
  kelinci('Kelinci', 250, Color(0xFFFAF6F1), EarShape.long),
  rubah(
    'Rubah',
    300,
    Color(0xFFE8844A),
    EarShape.pointed,
    marks: [
      (Color(0xFFFFF3E6), [(3, 9, 10, 3), (5, 12, 6, 1)]),
    ],
  ),
  katak('Katak', 350, Color(0xFFA5D47F), EarShape.bumps),
  panda(
    'Panda',
    400,
    Color(0xFFF7F7F4),
    EarShape.round,
    earFill: Color(0xFF4A4A4A),
    marks: [
      (Color(0xFFA3A3A3), [(2, 5, 4, 4), (10, 5, 4, 4)]),
    ],
  );

  const PetSpecies(
    this.label,
    this.price,
    this.fur,
    this.ears, {
    this.earFill,
    this.marks = const [],
  });

  @override
  final String label;
  @override
  final int price;
  @override
  ShopSlot get slot => ShopSlot.pet;
  @override
  String get id => name;

  final Color fur;
  final EarShape ears;

  /// Ear colour when it differs from [fur] (panda).
  final Color? earFill;

  /// Patches drawn over the fur, under the face (muzzle, eye patches).
  final List<PxLayer> marks;
}

enum Accessory implements ShopItem {
  pita('Pita Merah', 100, [
    (Color(0xFFE0566B), [(10, 0, 2, 3), (13, 0, 2, 3)]),
    (Color(0xFFA83246), [(12, 1, 1, 1)]),
  ]),
  topiPesta('Topi Pesta', 120, [
    (Color(0xFF6FA8DC), [(7, -3, 2, 1), (6, -2, 4, 1), (5, 0, 6, 1)]),
    (Color(0xFFF2C94C), [(7, -4, 2, 1), (6, -1, 4, 1), (5, 1, 6, 1)]),
  ]),
  kacamata('Kacamata Hitam', 150, [
    (Color(0xFF2F2F3A), [(2, 6, 4, 2), (10, 6, 4, 2), (6, 6, 4, 1)]),
    (Color(0xFFFFFFFF), [(3, 6, 1, 1), (11, 6, 1, 1)]),
  ]),
  syal('Syal Hangat', 180, [
    (Color(0xFFC2453B), [(3, 12, 10, 1), (4, 13, 8, 1)]),
    (
      Color(0xFFF4D35E),
      [
        (5, 12, 1, 1),
        (8, 12, 1, 1),
        (11, 12, 1, 1),
        (6, 13, 1, 1),
        (9, 13, 1, 1),
      ],
    ),
  ]),
  bunga('Bunga Sakura', 200, [
    (
      Color(0xFFF49AC1),
      [(2, -1, 1, 1), (1, 0, 1, 1), (3, 0, 1, 1), (2, 1, 1, 1)],
    ),
    (Color(0xFFF2C94C), [(2, 0, 1, 1)]),
  ]),
  topiPenyihir('Topi Penyihir', 350, [
    (
      Color(0xFF7B5BA6),
      [
        (3, 1, 10, 1),
        (6, -1, 4, 1),
        (7, -2, 3, 1),
        (8, -3, 2, 1),
        (10, -4, 1, 1),
      ],
    ),
    (Color(0xFFF2C94C), [(5, 0, 6, 1)]),
  ]),
  mahkota('Mahkota', 400, [
    (
      Color(0xFFF2C94C),
      [(5, -1, 1, 1), (7, -1, 2, 1), (10, -1, 1, 1), (5, 0, 6, 1)],
    ),
    (Color(0xFFC9962E), [(5, 1, 6, 1)]),
    (Color(0xFFE0566B), [(6, 0, 1, 1), (9, 0, 1, 1)]),
  ]);

  const Accessory(this.label, this.price, this.layers);

  @override
  final String label;
  @override
  final int price;
  @override
  ShopSlot get slot => ShopSlot.accessory;
  @override
  String get id => name;

  /// Drawn over the face, in order.
  final List<PxLayer> layers;
}

/// A colour theme for the whole app and Koko's room.
enum Habitat implements ShopItem {
  kamar(
    'Kamar Hangat',
    0,
    background: [Color(0xFFF8EFE4), Color(0xFFF3E8DA), Color(0xFFEFE6D8)],
    wall: Color(0xFFFBF1E6),
    floor: (Color(0xFFEEDCC4), Color(0xFFE7D2B6)),
    skirting: Color(0xFFE3CBAE),
    window: [Color(0xFFD7E6E6), Color(0xFFF7DCC2), Color(0xFFF2BE98)],
    nav: (Color(0xFFFCF1E2), Color(0xFFF6E7D3), Color(0xFFFDE2C0)),
  ),
  hutanBambu(
    'Hutan Bambu',
    300,
    background: [Color(0xFFEDF3E4), Color(0xFFE4EDD8), Color(0xFFDAE6CC)],
    wall: Color(0xFFF1F7E9),
    floor: (Color(0xFFD9E7C6), Color(0xFFCCDDB6)),
    skirting: Color(0xFFB4CB9B),
    window: [Color(0xFFD6EEF0), Color(0xFFE3F1D3), Color(0xFFB9DA9C)],
    nav: (Color(0xFFF0F6E7), Color(0xFFDFEBCF), Color(0xFFCDE2B4)),
  ),
  kutubEs(
    'Kutub Es',
    350,
    background: [Color(0xFFEBF3F8), Color(0xFFE2EDF5), Color(0xFFD8E6F0)],
    wall: Color(0xFFF2F8FC),
    floor: (Color(0xFFDFECF5), Color(0xFFD2E3EF)),
    skirting: Color(0xFFB5CDE0),
    window: [Color(0xFFC9E1F4), Color(0xFFE6F1FA), Color(0xFFFFFFFF)],
    nav: (Color(0xFFEFF5FA), Color(0xFFDDE9F3), Color(0xFFC8DEF0)),
  ),
  padangBunga(
    'Padang Bunga',
    400,
    background: [Color(0xFFFCEDF2), Color(0xFFF7E3EB), Color(0xFFF2D9E4)],
    wall: Color(0xFFFDF3F7),
    floor: (Color(0xFFF5DCE6), Color(0xFFEFCFDC)),
    skirting: Color(0xFFE2B2C6),
    window: [Color(0xFFFCE4ED), Color(0xFFF9D2E0), Color(0xFFF3B9CF)],
    nav: (Color(0xFFFCF0F5), Color(0xFFF6DEE8), Color(0xFFF2C8DA)),
  ),
  senjaPantai(
    'Senja Pantai',
    450,
    background: [Color(0xFFFDEDE0), Color(0xFFF9E2CF), Color(0xFFF4D7C1)],
    wall: Color(0xFFFEF4EA),
    floor: (Color(0xFFF3DEC3), Color(0xFFEDD1B0)),
    skirting: Color(0xFFDBB688),
    window: [Color(0xFFF9CB92), Color(0xFFF6A97F), Color(0xFFE88B7A)],
    nav: (Color(0xFFFDF1E5), Color(0xFFF8E3CD), Color(0xFFF5CEA6)),
  ),
  guaKristal(
    'Gua Kristal',
    500,
    background: [Color(0xFFF1ECF9), Color(0xFFE9E2F5), Color(0xFFE1D9F0)],
    wall: Color(0xFFF5F1FC),
    floor: (Color(0xFFE4DBF2), Color(0xFFD9CDEC)),
    skirting: Color(0xFFC1B0DF),
    window: [Color(0xFFD7CCF2), Color(0xFFE9E1F9), Color(0xFFCBBDEE)],
    nav: (Color(0xFFF3EFFB), Color(0xFFE4DDF4), Color(0xFFD5C9EE)),
  );

  const Habitat(
    this.label,
    this.price, {
    required this.background,
    required this.wall,
    required this.floor,
    required this.skirting,
    required this.window,
    required this.nav,
  });

  @override
  final String label;
  @override
  final int price;
  @override
  ShopSlot get slot => ShopSlot.habitat;
  @override
  String get id => name;

  /// App background gradient, top to bottom.
  final List<Color> background;
  final Color wall;

  /// Checker floor (light, dark).
  final (Color, Color) floor;
  final Color skirting;

  /// Sky in the room's window, top to bottom.
  final List<Color> window;

  /// Nav bar (bar, idle tile, selected pill).
  final (Color, Color, Color) nav;
}

/// What the user has equipped right now.
typedef Look = ({PetSpecies pet, Accessory? accessory, Habitat habitat});

const Look defaultLook = (
  pet: PetSpecies.kucing,
  accessory: null,
  habitat: Habitat.kamar,
);

T? _byName<T extends Enum>(List<T> values, String? name) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}

Look lookOf({String? pet, String? accessory, String? habitat}) => (
  pet: _byName(PetSpecies.values, pet) ?? PetSpecies.kucing,
  accessory: _byName(Accessory.values, accessory),
  habitat: _byName(Habitat.values, habitat) ?? Habitat.kamar,
);
