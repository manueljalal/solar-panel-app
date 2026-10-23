import 'dart:async';

import 'package:solary_marketplace/features/cart/domain/cart_item.dart';
import 'package:solary_marketplace/features/orders/data/order_repository.dart';
import 'package:solary_marketplace/features/orders/domain/order.dart';

/// Records checkout/cancel calls instead of hitting Cloud Functions, and
/// serves whatever orders a test puts in [orders].
class FakeOrderRepository implements OrderRepository {
  FakeOrderRepository({this.orders = const []});

  List<CustomerOrder> orders;
  final placed = <({List<CartItem> items, CheckoutDetails details})>[];
  final cancelled = <String>[];

  @override
  Future<String> placeOrder({required List<CartItem> items, required CheckoutDetails details}) async {
    placed.add((items: List.of(items), details: details));
    return 'abc123xyz';
  }

  @override
  Future<void> cancelOrder(String orderId) async => cancelled.add(orderId);

  @override
  Stream<List<CustomerOrder>> watchMyOrders(String uid) => Stream.value(orders);
}
