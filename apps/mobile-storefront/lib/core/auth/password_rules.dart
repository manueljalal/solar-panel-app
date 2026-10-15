/// Mirrors backend/functions/src/shared/auth/password.ts's isValidPassword —
/// fast client-side feedback only; the server is the real check.
bool isValidPassword(String password) {
  return password.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(password) &&
      RegExp(r'[a-z]').hasMatch(password) &&
      RegExp(r'[0-9]').hasMatch(password) &&
      RegExp(r'[^A-Za-z0-9]').hasMatch(password);
}
