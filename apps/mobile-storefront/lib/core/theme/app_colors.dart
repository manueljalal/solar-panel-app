import 'package:flutter/material.dart';

/// Storefront palette — deliberately neutral: near-black/white/gray does
/// almost all the work. Color (a single muted amber) is used only as a
/// thin accent — a dot, an underline, small text — never as a filled
/// block or a large surface. Previous versions leaned on solid dark-green
/// panels and solid gold pills, which read as "branded template" rather
/// than calm and neutral; this palette removes that.
class AppColors {
  AppColors._();

  static const ink900 = Color(0xFF1A1A1A); // headings, primary text
  static const ink600 = Color(0xFF6B6B6B); // secondary text
  static const ink400 = Color(0xFF9C9C9C); // placeholder/tertiary
  static const line = Color(0xFFE6E6E4); // hairline dividers only, not card outlines
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSunken = Color(0xFFF7F7F5); // near-white, barely-tinted page bg
  static const surfaceMuted = Color(0xFFF0F0EE); // flat neutral fill for icon chips, dark-mode-free "dark" cards

  /// The one accent color in the whole app. Used sparingly: a small dot,
  /// an underline, a rating star, small link text. Never a large fill.
  static const accent = Color(0xFFB8763E);

  /// Near-black used in place of the old solid-forest-green panels —
  /// same "distinct dark card" role, but neutral instead of a brand hue.
  static const ink = Color(0xFF232323);

  static const placeholderFill = Color(0xFFEDEDEB);
  static const placeholderIcon = Color(0xFFAFAFAC);

  static const success = Color(0xFF3D7A57);
  static const warning = Color(0xFFA3701F);

  /// Rotating tile backgrounds for the company directory — desaturated
  /// neutral tints (not the previous tan/sage/pink) so the row reads as
  /// "distinct cards" without adding color noise.
  static const companyTileTints = [
    Color(0xFFE8E7E3),
    Color(0xFFE3E5E4),
    Color(0xFFE5E4E6),
    Color(0xFFE3E6E7),
  ];

  static const houseIcon = Color(0xFF3A3A3A);
  static const houseIconRoof = Color(0xFFB8763E);
}
