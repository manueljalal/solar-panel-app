/// "+9647501234567" → "+964 750 123 4567" for display; other numbers are
/// returned unchanged.
String formatPhone(String e164) {
  final m = RegExp(r'^\+964(\d{3})(\d{3})(\d{4})$').firstMatch(e164);
  return m == null ? e164 : '+964 ${m[1]} ${m[2]} ${m[3]}';
}

final _e164 = RegExp(r'^\+[1-9]\d{6,14}$');

bool isValidE164(String phone) => _e164.hasMatch(phone);

/// Turns what people actually type into E.164: strips spaces/dashes/
/// parentheses, maps "00…" to "+…", and treats a local Iraqi mobile
/// ("0750 123 4567") as +964. Anything else is returned cleaned but
/// otherwise as typed, for the validator to judge.
String normalizePhone(String input) {
  var p = input.trim().replaceAll(RegExp(r'[\s\-().]'), '');
  if (p.startsWith('00')) p = '+${p.substring(2)}';
  if (RegExp(r'^07\d{9}$').hasMatch(p)) p = '+964${p.substring(1)}';
  return p;
}
