import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class AppRadii {
  AppRadii._();

  static const card = 18.0;
  static const searchBar = 999.0;
  static const avatar = 999.0;
  static const chip = 999.0;
}

/// Shared soft-shadow set — replaces flat 1px borders on cards. A single
/// diffuse, low-opacity shadow reads as "designed" rather than "boxed";
/// keep it consistent everywhere a card floats above the page background.
class AppShadows {
  AppShadows._();

  static const card = [
    BoxShadow(
      color: Color(0x14100E08), // ~8% black, warm-tinted
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0A100E08), // ~4% black, tight contact shadow
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];
}
