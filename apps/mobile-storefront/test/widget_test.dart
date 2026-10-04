import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:solary_marketplace/main.dart';

import 'support/fake_home_repository.dart';

void main() {
  testWidgets('App opens straight to the marketplace home, no login wall', (tester) async {
    await tester.pumpWidget(SolaryMarketplaceApp(homeRepository: FakeHomeRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Solary'), findsOneWidget);
    expect(find.text('Companies'), findsOneWidget);

    // "Best sellers" is further down the main CustomScrollView — scroll it
    // into view. The page also has a horizontal Companies ListView, so the
    // outer CustomScrollView must be named explicitly.
    await tester.scrollUntilVisible(
      find.text('Best sellers'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Best sellers'), findsOneWidget);
  });
}
