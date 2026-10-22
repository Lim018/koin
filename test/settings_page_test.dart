import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koin/core/db/user_state.dart';
import 'package:koin/core/providers.dart';
import 'package:koin/core/theme/app_theme.dart';
import 'package:koin/features/settings/settings_page.dart';

void main() {
  testWidgets('toggles read defaults and persist changes', (tester) async {
    // Tall enough that the whole "Profil" list is built at once.
    tester.view.physicalSize = const Size(1170, 4200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final saved = <String, Object?>{};
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('home_widget'),
      (call) async {
        final args = call.arguments as Map;
        switch (call.method) {
          case 'getWidgetData':
            return saved[args['id']] ?? args['defaultValue'];
          case 'saveWidgetData':
            saved[args['id'] as String] = args['data'];
            return true;
        }
        return true;
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userStateProvider.overrideWith(
            (ref) => Stream.value(UserState.initial(DateTime.now())),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(body: SettingsPage()),
        ),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Target hemat harian'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);

    SwitchListTile tile(String title) =>
        tester.widget(find.widgetWithText(SwitchListTile, title));
    expect(tile('Baca Notif GoPay').value, isTrue);
    expect(tile('E-Wallet lainnya').value, isFalse);
    expect(tile('Tanya sebelum mencatat').value, isTrue);

    await tester.tap(find.text('E-Wallet lainnya'));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(saved['koin_src_ewallet'], isTrue);
    expect(tile('E-Wallet lainnya').value, isTrue);
  });
}
