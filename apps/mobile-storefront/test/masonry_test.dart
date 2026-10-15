import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/main.dart';

import 'support/fake_home_repository.dart';

void main() {
  testWidgets('Featured masonry and product rows render with no overflow', (tester) async {
    await tester.pumpWidget(SolaryMarketplaceApp(homeRepository: FakeHomeRepository()));
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;

    await tester.scrollUntilVisible(find.text('Featured'), 300, scrollable: scrollable);
    expect(find.text('Featured'), findsOneWidget);
    expect(find.text('Wattage calculator'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Small steps: a 300px drag flings straight past this header.
    await tester.scrollUntilVisible(find.text('Best sellers'), 100, scrollable: scrollable);
    expect(find.text('Best sellers'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('\$189'), 100, scrollable: scrollable);
    expect(find.text('\$189'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
