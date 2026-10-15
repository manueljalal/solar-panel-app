import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/features/orders/domain/order.dart';
import 'package:solary_marketplace/features/orders/presentation/order_detail_screen.dart';

import 'support/fake_orders_repository.dart';
import 'support/test_app.dart';

CustomerOrder _order(String status, {List<String> reviewed = const []}) => CustomerOrder.fromJson({
      'id': 'abcdef1234_v1_USD',
      'vendorId': 'v1',
      'vendorName': 'SunBridge Energy',
      'status': status,
      'currency': 'USD',
      'subtotal': 761.5,
      'deliveryFee': 5,
      'total': 766.5,
      'contact': {'name': 'Ari', 'phone': '+9647501234567'},
      'address': {'text': 'Street 10', 'city': 'Erbil'},
      'note': '',
      'createdAt': 1760000000000,
      'items': [
        {'productId': 'p1', 'name': 'Panel 550W', 'nameI18n': null, 'imageUrl': '', 'unitPrice': 120.5, 'quantity': 3, 'lineTotal': 361.5},
      ],
      'statusHistory': [
        {'status': 'placed', 'at': 1760000000000, 'by': 'customer', 'note': ''},
      ],
      'reviewedProductIds': reviewed,
      'disputeStatus': null,
    });

Future<void> _open(WidgetTester tester, CustomerOrder order, FakeOrdersRepository repo) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(hostScreen(OrderDetailScreen(order: order, repository: repo)));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  test('order JSON from the callable parses into the model', () {
    final o = _order('installer_en_route');
    expect(o.status, OrderStatus.installerEnRoute);
    expect(o.itemCount, 3);
    expect(o.createdAt, isNotNull);
    expect(o.canConfirmInstallation, isTrue);
    expect(o.canCancel, isFalse);
  });

  testWidgets('a placed order can be cancelled after confirming', (tester) async {
    final repo = FakeOrdersRepository();
    await _open(tester, _order('placed'), repo);

    expect(find.text('Order #ABCDEF12'), findsOneWidget);
    expect(find.text('\$766.50'), findsOneWidget);
    expect(find.text('Confirm installation is done'), findsNothing);

    await tester.tap(find.text('Cancel order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(repo.statusChanges, [('abcdef1234_v1_USD', OrderStatus.cancelled)]);
  });

  testWidgets('installer en route: customer confirms installation, no cancel', (tester) async {
    final repo = FakeOrdersRepository();
    await _open(tester, _order('installer_en_route'), repo);

    expect(find.text('Cancel order'), findsNothing);
    await tester.tap(find.text('Confirm installation is done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(repo.statusChanges.single.$2, OrderStatus.installedVerified);
  });

  testWidgets('installed orders offer a review per product until reviewed', (tester) async {
    await _open(tester, _order('installed_verified'), FakeOrdersRepository());
    expect(find.text('Write a review'), findsOneWidget);
  });

  testWidgets('already-reviewed products show a thank-you instead', (tester) async {
    await _open(tester, _order('installed_verified', reviewed: ['p1']), FakeOrdersRepository());
    expect(find.text('Write a review'), findsNothing);
    expect(find.text('Reviewed — thank you'), findsOneWidget);
  });
}
