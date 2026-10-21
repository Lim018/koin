import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../add/transaction_form.dart';

/// The pop-up shown over the home screen by QuickAddActivity: a floating
/// card in the top half, leaving the bottom half to the system keyboard.
class QuickAddApp extends StatelessWidget {
  const QuickAddApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catat pengeluaran',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      color: Colors.transparent,
      home: const QuickAddScreen(),
    );
  }
}

class QuickAddScreen extends StatelessWidget {
  const QuickAddScreen({super.key});

  /// Finishes the Android activity, returning to the home screen.
  static void close() => SystemNavigator.pop();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Tapping outside the card dismisses the pop-up.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: close,
              child: Semantics(label: 'Tutup', button: true),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: const Alignment(0, -0.75),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        offset: Offset(0, 12),
                        blurRadius: 30,
                        spreadRadius: -12,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Catat pengeluaran',
                              style: text.titleMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Tutup',
                            onPressed: close,
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TransactionForm(compact: true, onSaved: (_) => close()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
