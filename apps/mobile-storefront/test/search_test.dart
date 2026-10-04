import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/features/search/data/search_repository.dart';
import 'package:solary_marketplace/features/search/presentation/search_screen.dart';
import 'package:solary_marketplace/l10n/app_localizations.dart';

import 'support/fake_home_repository.dart';

void main() {
  testWidgets('Search filters the product list by title', (tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is! NetworkImageLoadException) originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    // SearchScreen is normally reached by tapping the home search field,
    // but that navigation constructs its own (non-injectable) instance —
    // pump SearchScreen directly with a fake-backed repository instead, so
    // this test doesn't depend on real Firestore.
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: SearchScreen(repository: SearchRepository(homeRepository: FakeHomeRepository())),
      ),
    );
    await tester.pumpAndSettle();

    // No query yet — prompt shown, not results.
    expect(find.text('Search for panels, brands, or vendors.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'battery');
    await tester.pump(const Duration(milliseconds: 350)); // clear the debounce
    await tester.pumpAndSettle();

    expect(find.text('LUNA2000 Battery Unit'), findsOneWidget);
    expect(find.text('Tiger Neo Mono Panel'), findsNothing);

    await tester.enterText(find.byType(TextField), 'nonexistent brand xyz');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.textContaining('No results for'), findsOneWidget);
  });
}
