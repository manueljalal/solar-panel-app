import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';

void main() {
  runApp(const SolaryMarketplaceApp());
}

/// Customer-facing marketplace. No auth gate — browsing (and, later, cart/
/// checkout) works as a guest by default, matching the reference screens.
/// Account/login is offered from the Account tab, not forced up front.
class SolaryMarketplaceApp extends StatelessWidget {
  const SolaryMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solary',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
