import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:solary_marketplace/features/cart/data/cart_controller.dart';
import 'package:solary_marketplace/features/cart/data/cart_scope.dart';
import 'package:solary_marketplace/l10n/app_localizations.dart';

/// Hosts a single screen with the app's localizations and a cart, behind a
/// launcher button so the screen is pushed (and can pop a result).
Widget hostScreen(Widget screen, {CartController? cart, ValueChanged<Object?>? onPopped}) {
  return CartScope(
    controller: cart ?? CartController(),
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
                onPopped?.call(result);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}
