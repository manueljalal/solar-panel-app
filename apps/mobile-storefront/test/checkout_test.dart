import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/features/cart/data/cart_controller.dart';
import 'package:solary_marketplace/features/checkout/presentation/checkout_screen.dart';

import 'support/fake_orders_repository.dart';
import 'support/home_fixtures.dart';
import 'support/test_app.dart';

Future<void> _fill(WidgetTester tester, String label, String text) async {
  final field = find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
    matching: find.byType(TextFormField),
  );
  await tester.enterText(field, text);
}

void main() {
  testWidgets('checkout validates, places a COD order per vendor and clears the cart', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = FakeOrdersRepository();
    final cart = CartController()
      ..add(homeProducts[0], quantity: 2) // SunBridge
      ..add(homeProducts[1]); // Helios
    Object? popped;

    await tester.pumpWidget(hostScreen(CheckoutScreen(repository: repo), cart: cart, onPopped: (r) => popped = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Cash on delivery'), findsOneWidget);
    expect(find.text('SunBridge Energy'), findsOneWidget);
    expect(find.text('Helios Power Co.'), findsOneWidget);
    expect(find.textContaining('2 separate orders'), findsOneWidget);
    // $189 × 2 + $5 delivery
    expect(find.text('\$383'), findsOneWidget);

    // Empty form is refused before anything is sent.
    await tester.ensureVisible(find.text('Place order'));
    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();
    expect(repo.placed, isEmpty);
    expect(find.text('Required.'), findsWidgets);

    await _fill(tester, 'Full name', 'Ari Customer');
    await _fill(tester, 'Phone (WhatsApp)', '0750 123 4567');
    await _fill(tester, 'City', 'Erbil');
    await _fill(tester, 'Address', 'Street 10, House 4');
    await tester.ensureVisible(find.text('Place order'));
    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();

    expect(repo.placed, hasLength(1));
    final call = repo.placed.single;
    expect(call.delivery.phone, '+9647501234567', reason: 'local format normalized to E.164');
    expect(call.items.map((i) => (i.product.id, i.quantity)), [('p1', 2), ('p2', 1)]);
    expect(cart.isEmpty, isTrue);
    expect(popped, isA<List<String>>());
    expect((popped as List).length, 2);
  });
}
