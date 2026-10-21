import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/db/database.dart';
import 'core/detected_payment.dart';
import 'core/home_widget_sync.dart';
import 'core/providers.dart';
import 'features/automation/auto_log.dart';
import 'features/quick_add/quick_add_app.dart';

Future<void> main() async {
  final container = await _run(const KoinApp());
  // Daily coin reward: on launch and whenever the date rolls over.
  final repo = container.read(repositoryProvider);
  repo.awardDailyCoins(DateTime.now());
  container.listen(todayProvider, (_, today) => repo.awardDailyCoins(today));
  // Lets [YA, CATAT] on auto-read notifications run autoLogCallback in the
  // background; the handle survives restarts once registered.
  if (Platform.isAndroid) {
    await HomeWidget.registerInteractivityCallback(autoLogCallback);
  }
}

/// Entry point of the transparent QuickAddActivity, launched by the home
/// widget's "+ TAMBAH" (no args) or a notification's [UBAH] (args[0] is the
/// detected payment URI). See android/.../QuickAddActivity.kt.
@pragma('vm:entry-point')
Future<void> quickAddMain(List<String> args) => _run(
  QuickAddApp(
    prefill: args.isEmpty
        ? null
        : DetectedPayment.fromUri(Uri.tryParse(args.first)),
  ),
);

Future<ProviderContainer> _run(Widget app) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  final container = ProviderContainer(
    overrides: [isarProvider.overrideWithValue(await openDatabase())],
  );
  // Refresh the widget on launch too, so it never shows yesterday's total.
  syncHomeWidget(container.read(repositoryProvider));
  runApp(UncontrolledProviderScope(container: container, child: app));
  return container;
}
