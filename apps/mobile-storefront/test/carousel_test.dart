import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/main.dart';

import 'support/fake_home_repository.dart';

void main() {
  testWidgets('Banner carousel shows all 3 slides on swipe', (tester) async {
    await tester.pumpWidget(SolaryMarketplaceApp(homeRepository: FakeHomeRepository(withBanners: true)));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Zero down payment on residential kits'), findsOneWidget);

    final pageView = find.byType(PageView);
    expect(pageView, findsOneWidget);

    await tester.drag(pageView, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Battery storage, built for outages'), findsOneWidget);

    await tester.drag(pageView, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Every vendor, site-verified'), findsOneWidget);
  });
}
