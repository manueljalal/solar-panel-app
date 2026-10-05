/// "+9647501234567" → "+964 750 123 4567" for display; other numbers are
/// returned unchanged.
String formatPhone(String e164) {
  final m = RegExp(r'^\+964(\d{3})(\d{3})(\d{4})$').firstMatch(e164);
  return m == null ? e164 : '+964 ${m[1]} ${m[2]} ${m[3]}';
}
