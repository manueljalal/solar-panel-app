import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/features/home/domain/home_banner.dart';
import 'package:solary_marketplace/main.dart';

import 'support/fake_home_repository.dart';

HomeBanner _banner(String id, String title) =>
    HomeBanner(id: id, imageUrl: 'https://example.com/$id.jpg', titles: {'en': title});

void main() {
  testWidgets('Banner carousel shows every admin banner on swipe', (tester) async {
    await tester.pumpWidget(SolaryMarketplaceApp(
      homeRepository: FakeHomeRepository(banners: [
        _banner('a', 'Zero down payment'),
        _banner('b', 'Battery storage'),
        _banner('c', 'Every vendor, site-verified'),
      ]),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Zero down payment'), findsOneWidget);

    final pageView = find.byType(PageView);
    expect(pageView, findsOneWidget);

    await tester.drag(pageView, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Battery storage'), findsOneWidget);

    await tester.drag(pageView, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Every vendor, site-verified'), findsOneWidget);
  });
}
