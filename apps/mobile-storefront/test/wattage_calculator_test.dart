import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/main.dart';

import 'support/fake_home_repository.dart';

void main() {
  testWidgets('Wattage calculator opens from Home and updates live as inputs change', (tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is! NetworkImageLoadException) originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(SolaryMarketplaceApp(homeRepository: FakeHomeRepository()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Wattage calculator'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Wattage calculator').first);
    await tester.pumpAndSettle();

    // Default: 12 kWh / 6h -> 2.0 kW, ceil(2000/450) = 5 panels.
    expect(find.text('2.0 kW'), findsOneWidget);
    expect(find.text('5 panels · 450W each'), findsOneWidget);

    // Increase daily usage from 12 to 18 kWh (6 taps of +1).
    final plusButtons = find.byIcon(Icons.add);
    for (var i = 0; i < 6; i++) {
      await tester.tap(plusButtons.first);
      await tester.pump();
    }

    // 18 kWh / 6h = 3.0 kW, ceil(3000/450) = 7 panels.
    expect(find.text('3.0 kW'), findsOneWidget);
    expect(find.text('7 panels · 450W each'), findsOneWidget);
  });
}
