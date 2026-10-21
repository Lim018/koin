import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koin/core/categories.dart';
import 'package:koin/core/detected_payment.dart';
import 'package:koin/features/quick_add/quick_add_app.dart';

void main() {
  testWidgets('quick-add shows the compact form only', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: QuickAddApp()));
    await tester.pump();

    expect(find.text('Catat pengeluaran'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNWidgets(4));
    for (final c in ExpenseCategory.values.take(4)) {
      expect(find.textContaining(c.label), findsOneWidget);
    }
    expect(find.text('Sumber dana'), findsNothing);
    expect(find.text('Catatan (opsional)'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'SIMPAN'), findsOneWidget);
  });

  testWidgets('[UBAH] pre-fills amount, category and wallet', (tester) async {
    final prefill = DetectedPayment(
      amount: 25000,
      category: ExpenseCategory.tagihan,
      wallet: 'GoPay',
      timestamp: DateTime(2026, 10, 21, 12),
    );
    await tester.pumpWidget(
      ProviderScope(child: QuickAddApp(prefill: prefill)),
    );
    await tester.pump();

    expect(find.text('Cek transaksi GoPay'), findsOneWidget);
    expect(find.text('25.000'), findsOneWidget);
    // Tagihan is outside the compact four, so it is added as a fifth chip.
    expect(find.byType(ChoiceChip), findsNWidgets(5));
    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '🧾 Tagihan'),
    );
    expect(chip.selected, isTrue);
    final save = find.widgetWithText(FilledButton, 'SIMPAN');
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
  });
}
