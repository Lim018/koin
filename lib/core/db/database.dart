import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'transaction.dart';
import 'user_state.dart';

const schemas = [TransactionSchema, UserStateSchema];

Future<Isar> openDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(schemas, directory: dir.path, name: 'koin');
}
