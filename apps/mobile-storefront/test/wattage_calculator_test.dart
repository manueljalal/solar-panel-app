import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/main.dart';

import 'support/fake_home_repository.dart';

void main() {
  testWidgets('Calculator opens from Home and sizes an on-grid and a hybrid system', (tester) async {
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

    // On-grid, 5 kW load.
    await tester.enterText(find.widgetWithText(TextField, 'Load'), '5');
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
    expect(find.text('11 × 585W  ·  6.4 kWp'), findsOneWidget);
    expect(find.text('Batteries'), findsNothing);

    // Hybrid adds night load and batteries.
    await tester.ensureVisible(find.text('Hybrid'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hybrid'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Day load'), '3');
    await tester.enterText(find.widgetWithText(TextField, 'Night load'), '2');
    await tester.pumpAndSettle();
    expect(find.text('5 × 5.1 kWh  ·  25.6 kWh'), findsOneWidget);
  });
}
