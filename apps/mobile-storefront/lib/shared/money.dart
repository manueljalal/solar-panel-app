import 'bidi.dart';

/// "$189", "$1,240.50", "IQD 400,000" — left-to-right isolated so it reads
/// correctly inside Arabic / Sorani text.
String formatMoney(double amount, String currency) {
  final whole = amount == amount.roundToDouble();
  final fixed = whole ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  final number = parts.length > 1 ? '$buf.${parts[1]}' : buf.toString();
  return ltr(currency == 'USD' ? '\$$number' : '$currency $number');
}

/// Several currencies summed separately, e.g. "$1,240 + IQD 400,000".
String formatTotals(Map<String, double> totals) =>
    totals.entries.map((e) => formatMoney(e.value, e.key)).join(' + ');
