import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/main.dart';

import 'support/fake_home_repository.dart';

void main() {
  testWidgets('Tapping a product row opens its detail screen', (tester) async {
    await tester.pumpWidget(SolaryMarketplaceApp(homeRepository: FakeHomeRepository()));
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;

    // First seeded product: Tiger Neo Mono Panel.
    await tester.scrollUntilVisible(find.text('Tiger Neo Mono Panel'), 300, scrollable: scrollable);
    expect(find.text('Tiger Neo Mono Panel'), findsOneWidget);

    await tester.tap(find.text('Tiger Neo Mono Panel'));
    await tester.pumpAndSettle();

    // Detail screen shows title, price, spec strip label, and both actions.
    expect(find.text('Tiger Neo Mono Panel'), findsOneWidget);
    expect(find.text('\$189'), findsOneWidget);
    expect(find.text('Power'), findsOneWidget);
    expect(find.text('Request quote'), findsOneWidget);
    expect(find.text('Add to cart'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Back button returns to the home screen.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Best sellers'), findsOneWidget);
  });
}
