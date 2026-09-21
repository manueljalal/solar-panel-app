import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static const _family = 'Inter';

  static const h1 = TextStyle(
    fontFamily: _family,
    fontSize: 26,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    color: AppColors.ink900,
  );

  static const sectionTitle = TextStyle(
    fontFamily: _family,
    fontSize: 19,
    height: 1.3,
    fontWeight: FontWeight.w800,
    color: AppColors.ink900,
  );

  static const cardTitle = TextStyle(
    fontFamily: _family,
    fontSize: 14.5,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: AppColors.ink900,
  );

  static const body = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: AppColors.ink900,
  );

  static const bodyMuted = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w500,
    color: AppColors.ink600,
  );

  static const eyebrow = TextStyle(
    fontFamily: _family,
    fontSize: 12.5,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.gold,
  );

  static const link = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.gold,
  );

  static const price = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w800,
    color: AppColors.ink900,
  );
}
