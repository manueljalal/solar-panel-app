import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/main.dart';

void main() {
  testWidgets('Apply banner renders with photo background, no overflow', (tester) async {
    await tester.pumpWidget(const SolaryMarketplaceApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Own a solar business?'),
      400,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Own a solar business?'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
