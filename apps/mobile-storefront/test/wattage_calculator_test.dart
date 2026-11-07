import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/main.dart';

import 'support/fake_home_repository.dart';

void main() {
  testWidgets('Calculator opens from Home and sizes on-grid and hybrid systems live', (tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is! NetworkImageLoadException) originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(SolaryMarketplaceApp(homeRepository: FakeHomeRepository(), showSplash: false));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Wattage calculator'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Wattage calculator').first);
    await tester.pumpAndSettle();

    // Results are live: the default on-grid 5 kW load is already sized.
    // 5 × 1.25 = 6.25 kWp → 11 panels.
    await tester.scrollUntilVisible(find.text('11 panels × 585 W'), 200, scrollable: find.byType(Scrollable).last);
    expect(find.text('Batteries'), findsNothing);

    // Hybrid adds the night card (2 kW × 10 h by default) and batteries:
    // (5 + 20 / 5.5) × 1.25 = 10.8 kWp → 19 panels; 20 kWh / 0.855 → 5 modules.
    await tester.scrollUntilVisible(find.text('Hybrid'), -200, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Hybrid'));
    await tester.pumpAndSettle();
    expect(find.text('Night load'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('19 panels × 585 W'), 200, scrollable: find.byType(Scrollable).last);
    expect(find.text('19 panels × 585 W'), findsOneWidget);
    expect(find.text('25.6 kWh'), findsOneWidget);

    // Switching the battery off drops the night sizing again.
    await tester.scrollUntilVisible(find.byType(Switch), -200, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Night load'), findsNothing);
    await tester.scrollUntilVisible(find.text('11 panels × 585 W'), 200, scrollable: find.byType(Scrollable).last);
  });
}
