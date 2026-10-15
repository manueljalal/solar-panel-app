import 'package:solary_marketplace/features/cart/domain/cart_item.dart';
import 'package:solary_marketplace/features/orders/data/orders_repository.dart';
import 'package:solary_marketplace/features/orders/domain/order.dart';

/// In-memory OrdersRepository: records calls, never touches Firebase.
class FakeOrdersRepository implements OrdersRepository {
  FakeOrdersRepository({List<CustomerOrder>? orders, this.fees = const {'USD': 5, 'IQD': 0}})
      : orders = orders ?? [];

  final List<CustomerOrder> orders;
  final Map<String, double> fees;

  final placed = <({String checkoutId, List<CartItem> items, DeliveryDetails delivery})>[];
  final statusChanges = <(String, OrderStatus)>[];

  @override
  Future<Map<String, double>> fetchDeliveryFees() async => fees;

  @override
  Future<List<String>> placeOrder({
    required String checkoutId,
    required List<CartItem> items,
    required DeliveryDetails delivery,
  }) async {
    placed.add((checkoutId: checkoutId, items: items, delivery: delivery));
    final vendors = items.map((i) => '${i.product.vendorId}_${i.currency}').toSet();
    return [for (final v in vendors) '${checkoutId}_$v'];
  }

  @override
  Future<List<CustomerOrder>> listMyOrders() async => orders;

  @override
  Future<void> cancel(String orderId) async => statusChanges.add((orderId, OrderStatus.cancelled));

  @override
  Future<void> confirmInstallation(String orderId) async =>
      statusChanges.add((orderId, OrderStatus.installedVerified));

  @override
  Future<void> submitReview({required String orderId, required String productId, required int rating, String comment = ''}) async {}

  @override
  Future<void> openDispute({required String orderId, required String reason}) async {}

  @override
  Future<List<QuoteRequestSummary>> listMyQuoteRequests() async => const [];
}
