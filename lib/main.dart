import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/db/database.dart';
import 'core/home_widget_sync.dart';
import 'core/providers.dart';
import 'features/quick_add/quick_add_app.dart';

Future<void> main() => _run(const KoinApp());

/// Entry point of the transparent QuickAddActivity launched by the home
/// widget's "+ TAMBAH" button (see android/.../QuickAddActivity.kt).
@pragma('vm:entry-point')
Future<void> quickAddMain() => _run(const QuickAddApp());

Future<void> _run(Widget app) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  final container = ProviderContainer(
    overrides: [isarProvider.overrideWithValue(await openDatabase())],
  );
  // Refresh the widget on launch too, so it never shows yesterday's total.
  syncHomeWidget(container.read(repositoryProvider));
  runApp(UncontrolledProviderScope(container: container, child: app));
}
