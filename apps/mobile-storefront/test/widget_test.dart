import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/shared/widgets/solary_logo.dart';

import 'package:solary_marketplace/main.dart';

import 'support/fake_home_repository.dart';
import 'support/finders.dart';

void main() {
  testWidgets('App opens straight to the marketplace home, no login wall', (tester) async {
    await tester.pumpWidget(SolaryMarketplaceApp(homeRepository: FakeHomeRepository(), showSplash: false));
    await tester.pumpAndSettle();

    expect(find.byType(SolaryLogo), findsOneWidget);
    expect(find.text('Companies'), findsOneWidget);

    // "Best sellers" is further down the main CustomScrollView — scroll it
    // into view. The page also has a horizontal Companies ListView, so the
    // outer CustomScrollView must be named explicitly.
    await scrollHomeTo(tester, find.text('Best sellers'));
    expect(find.text('Best sellers'), findsOneWidget);
  });
}
