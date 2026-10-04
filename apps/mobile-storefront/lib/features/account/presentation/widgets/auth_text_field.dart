import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';

/// Shared labeled text field for the auth screens — matches the pattern
/// already used in vendor_apply_screen.dart / vendor_product_form_screen.dart.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.validator,
    this.forceLatinKeyboard = false,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;

  /// Forces the ASCII-only keyboard (same trick obscureText already uses)
  /// and disables autocorrect/suggestions on a field that ISN'T a
  /// password but still must never silently switch script — e.g.
  /// usernames, which the backend only accepts as
  /// lowercase-letters/digits/underscore.
  final bool forceLatinKeyboard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.cardTitle.copyWith(fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          // Password/username fields force the ASCII-capable Latin
          // keyboard and disable autocorrect/suggestions — without this,
          // iOS silently switches to whichever keyboard (Arabic, Sorani)
          // the user last used elsewhere, which is exactly the kind of
          // thing that should never happen on a credential field: a
          // password typed in the wrong script is a password that won't
          // match on the next sign-in, and the user often won't notice.
          keyboardType: (obscureText || forceLatinKeyboard) ? TextInputType.visiblePassword : keyboardType,
          autocorrect: !(obscureText || forceLatinKeyboard),
          enableSuggestions: !(obscureText || forceLatinKeyboard),
          autofillHints: autofillHints,
          validator: validator,
        ),
      ],
    );
  }
}
