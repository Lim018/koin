import 'package:intl/intl.dart';

final _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

/// `250000` → `Rp 250.000`.
String formatRupiah(num amount) => _rupiah.format(amount);
