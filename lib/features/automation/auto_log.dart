import 'package:flutter/widgets.dart';
import 'package:isar_community/isar.dart';

import '../../core/db/database.dart';
import '../../core/db/repository.dart';
import '../../core/detected_payment.dart';
import '../../core/home_widget_sync.dart';

/// Background isolate entry for [YA, CATAT] (and auto-log when confirmation
/// is off). Registered with HomeWidget.registerInteractivityCallback in main.
@pragma('vm:entry-point')
Future<void> autoLogCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  final payment = DetectedPayment.fromUri(uri);
  if (payment == null) {
    debugPrint('Auto-log ignored malformed payload: $uri');
    return;
  }
  final isar = Isar.getInstance(databaseName) ?? await openDatabase();
  await KoinRepository(isar, onChanged: syncHomeWidget).addTransaction(
    amount: payment.amount,
    category: payment.category.label,
    walletSource: payment.wallet,
    timestamp: payment.timestamp,
    isAutoLogged: true,
  );
}
