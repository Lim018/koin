import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koin/core/categories.dart';
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
}
