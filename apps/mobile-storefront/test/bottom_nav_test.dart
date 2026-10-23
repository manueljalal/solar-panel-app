import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/main.dart';

import 'support/fake_home_repository.dart';

/// Tab labels also appear in screen content (e.g. the home "Learn" teaser),
/// so tap the bottom nav's own copy.
Finder navTab(String label) =>
    find.descendant(of: find.byType(BottomNavigationBar), matching: find.text(label));

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
    expect(find.text('Learn'), findsWidgets);

    await tester.tap(navTab('Cart'));
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty'), findsOneWidget);

    await tester.tap(navTab('Orders'));
    await tester.pumpAndSettle();
    // No Firebase app in tests, so there's no signed-in user to list
    // orders for — the honest empty state.
    expect(find.text('No orders yet'), findsOneWidget);

    await tester.tap(navTab('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Account'), findsWidgets); // app bar title + tab label

    await tester.tap(navTab('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Solary'), findsOneWidget);
  });
}
