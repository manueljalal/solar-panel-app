import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/auth/auth_repository.dart';
import 'core/l10n/framework_locale_fallback.dart';
import 'core/l10n/locale_controller.dart';
import 'core/l10n/locale_scope.dart';
import 'core/navigation/root_shell.dart';
import 'core/theme/app_theme.dart';
import 'features/cart/data/cart_controller.dart';
import 'features/cart/data/cart_scope.dart';
import 'features/home/data/home_repository.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SolaryMarketplaceApp());

  // Fire-and-forget: browsing has no auth dependency (see class doc below),
  // so the home screen never waits on this. Cart/orders/favorites read
  // AuthRepository().currentUser when they need a uid, by which point this
  // has almost certainly already resolved.
  unawaited(AuthRepository().ensureSignedIn());
}

/// Customer-facing marketplace. No auth gate — browsing (and cart) works
/// as a guest by default, matching the reference screens. Account/login
/// upgrade is offered from the Account tab, not forced up front.
///
/// [homeRepository] is injectable so widget tests can pass a fake instead
/// of hitting real Firestore (see test/support/fake_home_repository.dart);
/// production code never passes it.
class SolaryMarketplaceApp extends StatefulWidget {
  const SolaryMarketplaceApp({super.key, this.homeRepository});

  final HomeRepository? homeRepository;

  @override
  State<SolaryMarketplaceApp> createState() => _SolaryMarketplaceAppState();
}

class _SolaryMarketplaceAppState extends State<SolaryMarketplaceApp> {
  final _cartController = CartController();
  final _localeController = LocaleController();

  @override
  void dispose() {
    _cartController.dispose();
    _localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      controller: _localeController,
      child: CartScope(
        controller: _cartController,
        child: ValueListenableBuilder<Locale>(
          valueListenable: _localeController,
          builder: (context, locale, _) {
            return MaterialApp(
              title: 'Solary',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              locale: locale,
              supportedLocales: LocaleController.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                FrameworkLocaleFallbackDelegate<MaterialLocalizations>(GlobalMaterialLocalizations.delegate),
                FrameworkLocaleFallbackDelegate<WidgetsLocalizations>(GlobalWidgetsLocalizations.delegate),
                FrameworkLocaleFallbackDelegate<CupertinoLocalizations>(GlobalCupertinoLocalizations.delegate),
              ],
              // No manual Directionality wrapper needed — MaterialApp derives
              // text direction from the active locale via
              // GlobalWidgetsLocalizations. ar resolves to RTL directly; ckb
              // has no Flutter-builtin locale data at all (confirmed via a
              // live crash) so FrameworkLocaleFallbackDelegate substitutes ar
              // for it on the three framework delegates only — same RTL
              // direction, while AppLocalizations still serves real ckb text
              // everywhere in the actual UI.
              home: RootShell(homeRepository: widget.homeRepository),
            );
          },
        ),
      ),
    );
  }
}
