import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/main.dart';

void main() {
  testWidgets('Banner carousel shows all 3 slides on swipe', (tester) async {
    await tester.pumpWidget(const SolaryMarketplaceApp());
    await tester.pumpAndSettle();

    expect(find.text('Zero down payment\non residential kits'), findsOneWidget);

    final pageView = find.byType(PageView);
    expect(pageView, findsOneWidget);

    await tester.drag(pageView, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Battery storage,\nbuilt for outages'), findsOneWidget);

    await tester.drag(pageView, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Every vendor,\nsite-verified'), findsOneWidget);
  });
}
