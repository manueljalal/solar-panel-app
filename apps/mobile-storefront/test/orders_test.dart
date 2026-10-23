import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/features/orders/domain/order.dart';
import 'package:solary_marketplace/features/orders/presentation/orders_screen.dart';
import 'package:solary_marketplace/l10n/app_localizations.dart';

import 'support/fake_order_repository.dart';

CustomerOrder _order(String status) => CustomerOrder.fromFirestore('k3f9qxAbCdEf', {
      'status': status,
      'itemCount': 3,
      'items': [
        {
          'productId': 'product-1',
          'name': 'Tiger Neo Mono Panel',
          'nameI18n': {'en': 'Tiger Neo Mono Panel', 'ar': 'لوح تايغر نيو', 'ku': 'پانێڵی تایگەر نیۆ'},
          'imageUrl': '',
          'unitPrice': 189,
          'currency': 'USD',
          'quantity': 2,
          'lineTotal': 378,
        },
        {
          'productId': 'product-9',
          'name': 'Mounting kit',
          'imageUrl': '',
          'unitPrice': 250000,
          'currency': 'IQD',
          'quantity': 1,
          'lineTotal': 250000,
        },
      ],
      'totals': {'USD': 378, 'IQD': 250000},
      'contact': {'name': 'Shene Ahmed', 'phone': '+9647501234567'},
      'delivery': {'city': 'Erbil', 'address': '100m Street', 'note': ''},
      'createdAt': Timestamp.fromDate(DateTime(2026, 10, 23, 12)),
    });

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  testWidgets('Orders tab lists the customer\'s orders with status and per-currency totals', (tester) async {
    final repo = FakeOrderRepository(orders: [_order('shipped')]);
    await tester.pumpWidget(_app(OrdersScreen(repository: repo, uid: 'u1')));
    await tester.pumpAndSettle();

    expect(find.text('Order #K3F9QX'), findsOneWidget);
    expect(find.text('On the way'), findsOneWidget);
    expect(find.text('Tiger Neo Mono Panel +1'), findsOneWidget);
    expect(find.text('2026-10-23 · 3 items'), findsOneWidget);
    expect(find.text('\$378 + IQD 250,000'), findsOneWidget);
  });

  testWidgets('An unconfirmed order can be cancelled from its detail screen', (tester) async {
    final repo = FakeOrderRepository(orders: [_order('placed')]);
    await tester.pumpWidget(_app(OrdersScreen(repository: repo, uid: 'u1')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Order #K3F9QX'));
    await tester.pumpAndSettle();
    expect(find.text('Order details'), findsOneWidget);
    expect(find.text('+964 750 123 4567'), findsOneWidget);

    await tester.dragUntilVisible(find.text('Cancel order'), find.byType(ListView), const Offset(0, -300));
    await tester.tap(find.text('Cancel order'));
    await tester.pumpAndSettle();
    // Confirmation dialog — its confirm button reuses the same label.
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Cancel order')));
    await tester.pumpAndSettle();

    expect(repo.cancelled, ['k3f9qxAbCdEf']);
    expect(find.text('Order cancelled.'), findsOneWidget);
    expect(find.text('Cancel order'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, 1000));
    await tester.pumpAndSettle();
    expect(find.text('Cancelled'), findsOneWidget);
  });

  testWidgets('A confirmed order has no cancel button', (tester) async {
    final repo = FakeOrderRepository(orders: [_order('confirmed')]);
    await tester.pumpWidget(_app(OrdersScreen(repository: repo, uid: 'u1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Order #K3F9QX'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(find.text('Cancel order'), findsNothing);
  });
}
