import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/main.dart';

import 'bottom_nav_test.dart' show navTab;
import 'support/fake_home_repository.dart';
import 'support/fake_order_repository.dart';

void main() {
  late void Function(FlutterErrorDetails)? originalOnError;

  setUp(() {
    // flutter_test's HttpClient answers every image request with a 400;
    // NetworkImageWithFallback shows its fallback icon, but the image codec
    // still reports the failure as a FlutterError. That's test-environment
    // noise, not an app bug — ignore only that exception type.
    originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is! NetworkImageLoadException) originalOnError?.call(details);
    };
  });
  tearDown(() => FlutterError.onError = originalOnError);

  Future<void> addTigerNeoToCart(WidgetTester tester) async {
    // The title appears in both Featured and Best sellers (so
    // scrollUntilVisible, which needs a single match, can't be used) —
    // scroll until either is on screen; both open the same product.
    final title = find.text('Tiger Neo Mono Panel').hitTestable();
    for (var i = 0; i < 20 && title.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Tiger Neo Mono Panel').hitTestable().first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();
    expect(find.text('Added Tiger Neo Mono Panel to cart.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    // Let the "Added to cart" SnackBar time out — it sits over the Cart
    // tab's Checkout button.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  testWidgets('Add to cart from product detail updates the Cart tab and nav badge', (tester) async {
    await tester.pumpWidget(SolaryMarketplaceApp(homeRepository: FakeHomeRepository()));
    await tester.pumpAndSettle();

    await addTigerNeoToCart(tester);

    // Cart nav badge shows "1".
    expect(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('1')), findsOneWidget);

    await tester.tap(navTab('Cart'));
    await tester.pumpAndSettle();

    expect(find.text('Tiger Neo Mono Panel'), findsOneWidget);
    expect(find.text('Subtotal (1 item)'), findsOneWidget);
  });

  testWidgets('Checkout validates, places the order, clears the cart and opens Orders', (tester) async {
    final orders = FakeOrderRepository();
    await tester.pumpWidget(SolaryMarketplaceApp(homeRepository: FakeHomeRepository(), orderRepository: orders));
    await tester.pumpAndSettle();

    await addTigerNeoToCart(tester);
    await tester.tap(navTab('Cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();

    // Submitting empty shows field errors and calls nothing.
    await tester.dragUntilVisible(find.text('Place order'), find.byType(ListView), const Offset(0, -300));
    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();
    expect(orders.placed, isEmpty);
    await tester.dragUntilVisible(find.text('Enter your name'), find.byType(ListView), const Offset(0, 300));
    expect(find.text('Enter your name'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Shene Ahmed');
    // Eastern Arabic digits, as a Kurdish keyboard types them.
    await tester.enterText(fields.at(1), '٠٧٥٠ ١٢٣ ٤٥٦٧');
    await tester.enterText(fields.at(2), 'Erbil');
    await tester.enterText(fields.at(3), '100m Street, near Family Mall');
    await tester.dragUntilVisible(find.text('Place order'), find.byType(ListView), const Offset(0, -300));
    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();

    expect(orders.placed, hasLength(1));
    final placed = orders.placed.single;
    expect(placed.items.single.product.id, 'product-1');
    expect(placed.items.single.quantity, 1);
    expect(placed.details.phone, '+9647501234567');
    expect(placed.details.city, 'Erbil');

    expect(find.text('Order placed'), findsOneWidget);
    expect(find.text('Order #ABC123'), findsOneWidget);

    await tester.tap(find.text('View my orders'));
    await tester.pumpAndSettle();
    expect(find.text('No orders yet'), findsOneWidget); // Orders tab is showing

    await tester.tap(navTab('Cart'));
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty'), findsOneWidget);
  });
}
