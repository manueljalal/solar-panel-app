import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/main.dart';

import 'support/fake_home_repository.dart';

void main() {
  testWidgets('Add to cart from product detail updates the Cart tab and nav badge', (tester) async {
    // NetworkImageWithFallback's own errorBuilder handles failed image
    // loads correctly (verified visually and in apply_banner_test.dart /
    // masonry_test.dart), but flutter_test's default HttpClient returning
    // 400 for every request means the underlying NetworkImageLoadException
    // still surfaces as an unhandled FlutterError from the image codec
    // pipeline — independent of whether the widget tree handles it. This
    // is a known flutter_test limitation (not an app bug): silence it for
    // this test only, since this test also exercises the Cart tab, which
    // IndexedStack builds eagerly and which real product images live in.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final isNetworkImageNoise = details.exception is NetworkImageLoadException;
      if (!isNetworkImageNoise) originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(SolaryMarketplaceApp(homeRepository: FakeHomeRepository()));
    await tester.pumpAndSettle();

    // Navigate into a product and add it to cart.
    await tester.scrollUntilVisible(
      find.text('Tiger Neo Mono Panel'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Tiger Neo Mono Panel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();
    expect(find.text('Added Tiger Neo Mono Panel to cart.'), findsOneWidget);

    // Back to home, then switch to the Cart tab via bottom nav.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Cart nav badge shows "1".
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();

    expect(find.text('Tiger Neo Mono Panel'), findsOneWidget);
    expect(find.text('Subtotal (1 item)'), findsOneWidget);
  });
}
