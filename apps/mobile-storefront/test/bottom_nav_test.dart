import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/main.dart';

import 'support/fake_home_repository.dart';
import 'support/finders.dart';

void main() {
  testWidgets('All 5 bottom nav tabs navigate to real, distinct screens', (tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is! NetworkImageLoadException) originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(SolaryMarketplaceApp(homeRepository: FakeHomeRepository()));
    await tester.pumpAndSettle();

    // Home is the default tab.
    expect(find.text('Solary'), findsOneWidget);

    await tester.tap(navTab('Learn'));
    await tester.pumpAndSettle();
    expect(find.text('Learn'), findsWidgets); // app bar title + tab label

    await tester.tap(navTab('Cart'));
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty'), findsOneWidget);

    await tester.tap(navTab('Orders'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in to see your orders'), findsOneWidget); // no account in tests

    await tester.tap(navTab('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Account'), findsWidgets); // app bar title + tab label
    // No Firebase.initializeApp() in the test environment, so this
    // correctly shows the "not signed in" state rather than a real uid —
    // see AccountScreen's Firebase.apps.isEmpty guard.
    expect(find.text('Not signed in'), findsOneWidget);

    await tester.tap(navTab('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Solary'), findsOneWidget);
  });
}
