import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/main.dart';

import 'support/fake_home_repository.dart';

/// Taps a bottom-nav item by label — the same word can also appear in the
/// page itself (e.g. the Home feed's "Learn" teaser).
Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

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

    // Learn content comes from Firestore, which isn't initialized in tests:
    // the tab still opens and shows its error/retry state instead of crashing.
    await _tapTab(tester, 'Learn');
    expect(find.text("Couldn't load content. Check your connection."), findsOneWidget);

    await _tapTab(tester, 'Cart');
    expect(find.text('Your cart is empty'), findsOneWidget);

    await _tapTab(tester, 'Orders');
    expect(find.text('No orders yet'), findsOneWidget);

    await _tapTab(tester, 'Account');
    expect(find.text('Account'), findsWidgets); // app bar title + tab label
    // No Firebase.initializeApp() in the test environment, so this
    // correctly shows the "not signed in" state rather than a real uid —
    // see AccountScreen's Firebase.apps.isEmpty guard.
    expect(find.text('Not signed in'), findsOneWidget);

    await _tapTab(tester, 'Home');
    expect(find.text('Solary'), findsOneWidget);
  });
}
