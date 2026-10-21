import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:koin/app.dart';
import 'package:koin/core/budget/budget.dart';
import 'package:koin/core/db/transaction.dart';
import 'package:koin/core/db/user_state.dart';
import 'package:koin/core/providers.dart';
import 'package:koin/features/diary/diary_list.dart';
import 'package:koin/ui/cozy.dart';

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
    expect(find.widgetWithText(PageHeader, 'Beranda'), findsOneWidget);
    expect(find.textContaining('Senang', findRichText: true), findsOneWidget);
    expect(find.textContaining('Belum ada catatan'), findsOneWidget);
  });

  testWidgets('over budget turns Koko grumpy and lists entries', (
    tester,
  ) async {
    await pumpApp(tester, [tx(250000, 'Sepatu lari')]);
    expect(find.textContaining('Kesal', findRichText: true), findsOneWidget);
    expect(find.text('Sepatu lari'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DiaryList),
        matching: find.text('−Rp 250.000'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('every tab renders under its own header', (tester) async {
    await pumpApp(tester, [tx(45000, 'Nasi padang')]);

    await tester.tap(find.byIcon(Icons.calendar_month_rounded));
    await tester.pump();
    await tester.pump();
    expect(find.widgetWithText(PageHeader, 'Kalender'), findsOneWidget);
    expect(find.text('Total Pengeluaran Bulan Ini'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bar_chart_rounded));
    await tester.pump();
    await tester.pump();
    expect(find.widgetWithText(PageHeader, 'Insight'), findsOneWidget);

    // The daily target lives in "Atur", next to the other settings.
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();
    await tester.pump();
    expect(find.widgetWithText(PageHeader, 'Atur'), findsOneWidget);
    expect(find.text('Target hemat harian'), findsOneWidget);
    expect(find.text('Simpan target'), findsOneWidget);
  });

  testWidgets('+ opens the add sheet with save disabled until an amount', (
    tester,
  ) async {
    await pumpApp(tester, []);
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Catat transaksi'), findsOneWidget);
    final save = find.widgetWithText(FilledButton, 'SIMPAN');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, '25000');
    await tester.pump();
    expect(find.text('25.000'), findsOneWidget);
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
  });

  testWidgets('tapping a diary entry opens it for editing', (tester) async {
    await pumpApp(tester, [tx(45000, 'Nasi padang')]);
    await tester.tap(find.text('Nasi padang'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Ubah catatan'), findsOneWidget);
    expect(find.widgetWithText(TextField, '45.000'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Nasi padang'), findsOneWidget);
    final save = find.widgetWithText(FilledButton, 'SIMPAN');
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
  });

  testWidgets('coin chip explains how coins are earned', (tester) async {
    await pumpApp(tester, [tx(45000, 'Nasi padang')]);
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Saldo 0 koin',
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('0 koin'), findsOneWidget);
    expect(find.textContaining('Hari ini masih aman'), findsOneWidget);
  });

  testWidgets('income shows as +Rp and keeps Koko happy', (tester) async {
    await pumpApp(tester, [
      tx(5000000, 'Gaji Oktober')
        ..category = 'Gaji'
        ..kind = TransactionKind.income,
      tx(45000, 'Nasi padang'),
    ]);
    expect(find.textContaining('Senang', findRichText: true), findsOneWidget);
    expect(find.text('+Rp 5.000.000'), findsWidgets);
    expect(find.text('Keluar Rp 45.000'), findsOneWidget);
    expect(find.text('Masuk bulan ini'), findsOneWidget);
  });

  testWidgets('switching the sheet to income shows income categories', (
    tester,
  ) async {
    await pumpApp(tester, []);
    await tester.tap(find.byIcon(Icons.add_rounded));
    // Two frames: the sheet is still sliding in after the first.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('🍔 Makan'), findsOneWidget);

    await tester.tap(find.text('Pemasukan'));
    await tester.pump();
    expect(find.text('💼 Gaji'), findsOneWidget);
    expect(find.text('🍔 Makan'), findsNothing);
    expect(find.text('Masuk ke'), findsOneWidget);
  });
}
