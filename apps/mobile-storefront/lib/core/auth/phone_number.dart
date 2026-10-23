/// "+9647501234567" → "+964 750 123 4567" for display; other numbers are
/// returned unchanged.
String formatPhone(String e164) {
  final m = RegExp(r'^\+964(\d{3})(\d{3})(\d{4})$').firstMatch(e164);
  return m == null ? e164 : '+964 ${m[1]} ${m[2]} ${m[3]}';
}

/// Same rules as the server's normalizePhone (backend/functions/src/shared/
/// orders/order_status.ts): accepts "0750 123 4567", "00964…" or
/// "+964 750-123-4567" — in Western or Eastern Arabic digits (٠٧٥٠…, which
/// Arabic/Kurdish keyboards type) — and returns E.164, or null if it still
/// isn't valid.
String? normalizePhoneInput(String input) {
  var phone = input
      .replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m[0]!.codeUnitAt(0) - 0x0660}')
      .replaceAllMapped(RegExp('[۰-۹]'), (m) => '${m[0]!.codeUnitAt(0) - 0x06F0}')
      .replaceAll(RegExp(r'[\s\-().]'), '');
  if (phone.startsWith('00')) phone = '+${phone.substring(2)}';
  if (RegExp(r'^07\d{9}$').hasMatch(phone)) phone = '+964${phone.substring(1)}';
  return RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(phone) ? phone : null;
}
