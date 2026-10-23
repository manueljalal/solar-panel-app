/// "$189", "$1,240.50", "IQD 250,000". Matches how HomeProduct formats a
/// single price, plus thousands separators for totals.
String formatMoney(double amount, String currency) {
  final whole = amount.truncateToDouble() == amount;
  final fixed = amount.toStringAsFixed(whole ? 0 : 2);
  final parts = fixed.split('.');
  final grouped = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  final number = parts.length > 1 ? '$grouped.${parts[1]}' : grouped;
  return currency == 'USD' ? '\$$number' : '$currency $number';
}

/// Products are priced in USD or IQD and the two are never added
/// together — a mixed cart shows "$189 + IQD 250,000".
String formatTotals(Map<String, double> totals) {
  if (totals.isEmpty) return formatMoney(0, 'USD');
  final currencies = totals.keys.toList()..sort((a, b) => a == 'USD' ? -1 : (b == 'USD' ? 1 : a.compareTo(b)));
  return currencies.map((c) => formatMoney(totals[c]!, c)).join(' + ');
}
