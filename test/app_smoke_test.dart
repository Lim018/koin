import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:koin/app.dart';
import 'package:koin/core/budget/budget.dart';
import 'package:koin/core/db/account.dart';
import 'package:koin/core/db/transaction.dart';
import 'package:koin/core/db/user_state.dart';
import 'package:koin/core/providers.dart';
import 'package:koin/features/diary/diary_list.dart';
import 'package:koin/ui/cozy.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  Future<void> pumpApp(
    WidgetTester tester,
    List<Transaction> txs, {
    int coins = 0,
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userStateProvider.overrideWith(
            (ref) => Stream.value(
              UserState.initial(DateTime.now())..savedCoins = coins,
            ),
          ),
          accountsProvider.overrideWith(
            (ref) => Stream.value([
              for (final (i, a) in Account.defaults().indexed) a..id = i + 1,
            ]),
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

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == label,
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

    // Calendar and chart share the "Statistik" tab.
    await openTab(tester, 'Statistik');
    expect(find.widgetWithText(PageHeader, 'Statistik'), findsOneWidget);
    expect(find.text('Total Pengeluaran Bulan Ini'), findsOneWidget);
    await tester.tap(find.text('Grafik'));
    await tester.pump();
    expect(find.text('Total Pengeluaran Bulan Ini'), findsNothing);
    expect(find.widgetWithText(PageHeader, 'Statistik'), findsOneWidget);
    // The pie breakdown lists the entry's category at 100%.
    expect(find.text('100%'), findsOneWidget);

    await openTab(tester, 'Bank');
    expect(find.widgetWithText(PageHeader, 'Bank'), findsOneWidget);
    expect(find.text('Total saldo'), findsOneWidget);
    expect(find.text('M-Banking'), findsOneWidget);

    // The daily target lives in "Profil", next to the other settings.
    await openTab(tester, 'Profil');
    expect(find.widgetWithText(PageHeader, 'Profil'), findsOneWidget);
    expect(find.text('Target pengeluaran harian'), findsOneWidget);
    expect(find.text('Simpan target'), findsOneWidget);
  });

  testWidgets('the pencil only floats on Beranda', (tester) async {
    await pumpApp(tester, []);
    expect(find.byTooltip('Catat transaksi'), findsOneWidget);
    await openTab(tester, 'Bank');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byTooltip('Catat transaksi'), findsNothing);
  });

  testWidgets('bank balances follow the entries on each account', (
    tester,
  ) async {
    await pumpApp(tester, [
      tx(5000000, 'Gaji')
        ..kind = TransactionKind.income
        ..walletSource = 'M-Banking',
      tx(45000, 'Nasi padang'),
    ]);
    await openTab(tester, 'Bank');
    expect(find.text('Rp 5.000.000'), findsOneWidget);
    expect(find.text('−Rp 45.000'), findsOneWidget);
    expect(find.text('Rp 4.955.000'), findsOneWidget);
  });

  testWidgets('+ opens the add sheet with save disabled until an amount', (
    tester,
  ) async {
    await pumpApp(tester, []);
    await tester.tap(find.byTooltip('Catat transaksi'));
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
    // Centre it so the nav bar and pencil do not cover the row.
    await tester.scrollUntilVisible(find.text('Nasi padang'), 300);
    await tester.drag(find.byType(ListView).first, const Offset(0, -200));
    await tester.pump();
    await tester.tap(find.text('Nasi padang'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Ubah catatan'), findsOneWidget);
    expect(find.widgetWithText(TextField, '45.000'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Nasi padang'), findsOneWidget);
    final save = find.widgetWithText(FilledButton, 'SIMPAN');
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
  });

  Future<void> openShop(WidgetTester tester, int coins) async {
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Saldo $coins koin',
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('coin chip opens Toko Koko, whose pill explains coins', (
    tester,
  ) async {
    await pumpApp(tester, [tx(45000, 'Nasi padang')]);
    await openShop(tester, 0);
    expect(find.widgetWithText(PageHeader, 'Toko Koko'), findsOneWidget);
    expect(find.text('Kelinci'), findsOneWidget);

    await tester.tap(find.text('Aksesoris'));
    await tester.pump();
    expect(find.text('Mahkota'), findsOneWidget);
    await tester.tap(find.text('Habitat'));
    await tester.pump();
    expect(find.text('Kutub Es'), findsOneWidget);

    await tester.tap(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label == 'Saldo 0 koin, cara dapat koin',
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('0 koin'), findsOneWidget);
    expect(find.textContaining('Hari ini masih aman'), findsOneWidget);
  });

  testWidgets('shop only lets you buy what you can afford', (tester) async {
    await pumpApp(tester, [], coins: 260);
    await openShop(tester, 260);
    // The starting pet is free and already worn.
    await tester.tap(find.text('Koko si Kucing'));
    await tester.pump();
    expect(find.widgetWithText(FilledButton, 'Dipakai'), findsOneWidget);

    await tester.tap(find.text('Kelinci'));
    await tester.pump();
    final buy = find.widgetWithText(FilledButton, 'Beli');
    expect(tester.widget<FilledButton>(buy).onPressed, isNotNull);

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();
    await tester.tap(find.text('Panda'));
    await tester.pump();
    // Back up to the preview, where the buy button lives.
    await tester.drag(find.byType(ListView), const Offset(0, 800));
    await tester.pump();
    expect(find.text('Kurang 140 koin lagi'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '400 koin'))
          .onPressed,
      isNull,
    );
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
    expect(find.text('Pemasukan'), findsOneWidget);
  });

  testWidgets('switching the sheet to income shows income categories', (
    tester,
  ) async {
    await pumpApp(tester, []);
    await tester.tap(find.byTooltip('Catat transaksi'));
    // Two frames: the sheet is still sliding in after the first.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('🍔 Makan'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byWidgetPredicate((w) => w is SegmentedButton),
        matching: find.text('Pemasukan'),
      ),
    );
    await tester.pump();
    expect(find.text('💼 Gaji'), findsOneWidget);
    expect(find.text('🍔 Makan'), findsNothing);
    expect(find.text('Masuk ke'), findsOneWidget);
  });
}
