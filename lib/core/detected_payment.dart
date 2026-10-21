import 'categories.dart';

/// A payment detected by the native notification listener, passed to Dart as
/// `koin://payment?amount=…&category=…&wallet=…&ts=…`
/// (see android/.../KoinNotificationListener.kt `detectedUri`).
class DetectedPayment {
  const DetectedPayment({
    required this.amount,
    required this.category,
    required this.wallet,
    required this.timestamp,
  });

  final double amount;
  final ExpenseCategory category;
  final String wallet;
  final DateTime timestamp;

  /// Null for anything that is not a well-formed, positive payment.
  static DetectedPayment? fromUri(Uri? uri) {
    if (uri == null || uri.scheme != 'koin' || uri.host != 'payment') {
      return null;
    }
    final q = uri.queryParameters;
    final amount = double.tryParse(q['amount'] ?? '');
    final ts = int.tryParse(q['ts'] ?? '');
    final wallet = q['wallet']?.trim() ?? '';
    if (amount == null ||
        !(amount > 0) ||
        wallet.isEmpty ||
        wallet.length > 30) {
      return null;
    }
    return DetectedPayment(
      amount: amount,
      category: ExpenseCategory.fromLabel(q['category'] ?? ''),
      wallet: wallet,
      timestamp: ts == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(ts),
    );
  }
}
