import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:koin/app.dart';
import 'package:koin/core/budget/budget.dart';
import 'package:koin/core/db/transaction.dart';
import 'package:koin/core/db/user_state.dart';
import 'package:koin/core/providers.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  Future<void> pumpApp(WidgetTester tester, List<Transaction> txs) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userStateProvider.overrideWith(
            (ref) => Stream.value(UserState.initial(DateTime.now())),
          ),
          transactionsProvider.overrideWith(
            (ref, DateRange range) => Stream.value([
              for (final t in txs)
                if (!t.timestamp.isBefore(range.start) &&
                    t.timestamp.isBefore(range.end))
                  t,
            ]),
          ),
        ],
        child: const KoinApp(),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Transaction tx(double amount, String note) => Transaction()
    ..id = amount.toInt()
    ..timestamp = DateTime.now()
    ..amount = amount
    ..category = 'Makan'
    ..walletSource = 'Cash'
    ..note = note;

  testWidgets('dashboard shows happy Koko and an empty diary', (tester) async {
    await pumpApp(tester, []);
    expect(find.text('Halo lagi'), findsOneWidget);
    expect(find.textContaining('Senang', findRichText: true), findsOneWidget);
    expect(find.textContaining('Belum ada catatan'), findsOneWidget);
  });

  testWidgets('over budget turns Koko grumpy and lists entries', (
    tester,
  ) async {
    await pumpApp(tester, [tx(250000, 'Sepatu lari')]);
    expect(find.textContaining('Kesal', findRichText: true), findsOneWidget);
    expect(find.text('Sepatu lari'), findsOneWidget);
    expect(find.text('−Rp 250.000'), findsOneWidget);
  });

  testWidgets('calendar and insight tabs render', (tester) async {
    await pumpApp(tester, [tx(45000, 'Nasi padang')]);

    await tester.tap(find.byIcon(Icons.calendar_month_rounded));
    await tester.pump();
    await tester.pump();
    expect(find.text('Total Pengeluaran Bulan Ini'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bar_chart_rounded));
    await tester.pump();
    await tester.pump();
    expect(find.text('Target hemat harian'), findsOneWidget);
    expect(find.text('Simpan target'), findsOneWidget);
  });

  testWidgets('+ opens the add sheet with save disabled until an amount', (
    tester,
  ) async {
    await pumpApp(tester, []);
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Catat pengeluaran'), findsWidgets);
    final save = find.widgetWithText(FilledButton, 'SIMPAN');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, '25000');
    await tester.pump();
    expect(find.text('25.000'), findsOneWidget);
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
  });
}
