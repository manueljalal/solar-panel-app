import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/core/l10n/locale_controller.dart';
import 'package:solary_marketplace/core/l10n/locale_scope.dart';
import 'package:solary_marketplace/core/navigation/root_shell.dart';
import 'package:solary_marketplace/main.dart';

import 'support/fake_home_repository.dart';

void main() {
  // Regression test for a real crash: Flutter's built-in Material/Widgets/
  // Cupertino localizations ship no Sorani Kurdish ('ckb') data at all, so
  // switching the app locale to ckb without a fallback threw "No
  // MaterialLocalizations found" and took down the whole widget tree
  // (every screen under RootShell, not just one). Fixed by
  // FrameworkLocaleFallbackDelegate substituting Arabic for ckb on those
  // three framework delegates specifically — this test exercises every
  // supported locale through the real app shell so that regression can't
  // silently come back.
  for (final locale in LocaleController.supportedLocales) {
    testWidgets('App renders the bottom nav shell without crashing in locale "${locale.languageCode}"',
        (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exception is! NetworkImageLoadException) originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(SolaryMarketplaceApp(homeRepository: FakeHomeRepository()));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(RootShell));
      LocaleScope.of(context).setLocale(locale);
      await tester.pumpAndSettle();

      // If localization resolution had failed, pumpAndSettle above would
      // have thrown (or FlutterError.onError would have recorded a real
      // exception) before reaching here. Also assert the shell actually
      // rendered real content, not an error screen.
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
