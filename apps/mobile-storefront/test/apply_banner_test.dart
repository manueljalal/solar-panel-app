import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/main.dart';

import 'support/fake_home_repository.dart';

void main() {
  testWidgets('Apply banner renders with photo background, no overflow', (tester) async {
    await tester.pumpWidget(SolaryMarketplaceApp(homeRepository: FakeHomeRepository()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Own a solar\nbusiness?'),
      400,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Own a solar\nbusiness?'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
