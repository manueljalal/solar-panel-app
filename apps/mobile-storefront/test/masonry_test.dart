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

    await tester.scrollUntilVisible(find.text('Best sellers'), 300, scrollable: scrollable);
    expect(find.text('Best sellers'), findsOneWidget);
    expect(find.textContaining('sold'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
