import 'package:isar_community/isar.dart';

import 'transaction.dart';

part 'custom_category.g.dart';

/// A category the user added; transactions refer to it by [label], like the
/// built-in ones (see `Categories` in categories.dart).
@collection
class CustomCategory {
  Id id = Isar.autoIncrement;

  @Index(caseSensitive: false)
  late String label;

  late String emoji;

  @enumerated
  TransactionKind kind = TransactionKind.expense;
}
