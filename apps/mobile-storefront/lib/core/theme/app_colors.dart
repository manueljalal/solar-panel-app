import 'package:flutter/material.dart';

/// Storefront palette — matches the reference marketplace screens exactly:
/// white surfaces, near-black text/headings, warm gold for category labels
/// and links, forest green only for vendor avatar chips.
class AppColors {
  AppColors._();

  static const ink900 = Color(0xFF14161A); // headings, primary text
  static const ink600 = Color(0xFF5B5F58); // secondary text (location, vendor names)
  static const ink400 = Color(0xFF8A8E82); // placeholder/tertiary
  static const line = Color(0xFFEDEBE2); // hairline dividers only, not card outlines
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSunken = Color(0xFFFAF8F3); // warm off-white page bg — pure white read as flat/templated

  static const gold = Color(0xFFC08A3E); // category eyebrow, "See all", ratings star
  static const forest = Color(0xFF1B3A2C); // dark cards (wattage calculator badge)

  static const placeholderFill = Color(0xFFEDEBE3);
  static const placeholderIcon = Color(0xFFB9B6A8);

  static const success = Color(0xFF2E7D4F);
  static const warning = Color(0xFFC97A1E);

  /// Rotating tile backgrounds for the company directory — each vendor gets
  /// a distinct soft tint instead of one repeated flat color, so the row
  /// reads as a set of real cards rather than a template stamped 3x.
  static const companyTileTints = [
    Color(0xFFE8D9B5), // warm tan
    Color(0xFFCFE0CE), // sage
    Color(0xFFE8CCC9), // dusty pink
    Color(0xFFC9DCE0), // pale teal
  ];

  static const houseIcon = Color(0xFF1B3A2C); // roofline/house illustration
  static const houseIconRoof = Color(0xFFC08A3E); // window accents

  static const accentInkOnGold = Color(0xFF2A1D07); // text placed on a solid gold fill
}
