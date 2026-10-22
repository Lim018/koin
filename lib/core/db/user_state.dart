import 'package:isar_community/isar.dart';

part 'user_state.g.dart';

/// Single-row collection holding the user's settings and game state.
@collection
class UserState {
  /// Fixed id so there is only ever one row (the PRD's autoIncrement would
  /// allow duplicates).
  static const singletonId = 0;

  Id id = singletonId;
  late double dailyBudgetTarget;
  late int savedCoins; // Currency for gamification/mascot room
  late DateTime lastUpdated;

  /// Last day already evaluated for the daily coin reward (local midnight);
  /// null until the first evaluation.
  DateTime? coinsAwardedThrough;

  /// Toko Koko purchases as [ShopItemKey.key]s; free items are not listed.
  List<String> ownedItems = [];

  /// Equipped item names (enum `name`s in catalog.dart); null = default.
  String? pet;
  String? accessory;
  String? habitat;

  static const defaultDailyBudget = 200000.0;

  static UserState initial(DateTime now) => UserState()
    ..dailyBudgetTarget = defaultDailyBudget
    ..savedCoins = 0
    ..lastUpdated = now;
}
