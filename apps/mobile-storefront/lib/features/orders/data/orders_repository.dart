import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../../../shared/location/picked_location.dart';
import '../../cart/domain/cart_item.dart';
import '../domain/order.dart';

/// Orders go through the storefront-* callables (Firestore rules refuse
/// direct client access to `orders`). Prices are re-read on the server;
/// the client only sends product ids and quantities.
class OrdersRepository {
  OrdersRepository({FirebaseFunctions? functions}) : _injected = functions;

  final FirebaseFunctions? _injected;
  FirebaseFunctions get _functions => _injected ?? FirebaseFunctions.instance;

  /// Bumped after an order is placed or cancelled, so an Orders screen that
  /// is kept alive in the tab stack knows to reload.
  static final changes = ValueNotifier<int>(0);

  /// [requestId] must stay the same for retries of one checkout, so the
  /// server can return the existing orders instead of creating duplicates.
  Future<List<String>> placeOrder({
    required List<CartItem> items,
    required String address,
    required PickedLocation location,
    required String requestId,
    String note = '',
  }) async {
    final result = await _functions.httpsCallable('storefront-placeOrder').call({
      'items': [
        for (final i in items) {'productId': i.product.id, 'qty': i.quantity},
      ],
      'address': address,
      'location': location.toJson(),
      'note': note,
      'requestId': requestId,
    });
    changes.value++;
    return [for (final id in ((result.data as Map)['orderIds'] as List? ?? const [])) id as String];
  }

  Future<List<CustomerOrder>> listMine() async {
    final result = await _functions.httpsCallable('storefront-listMyOrders').call();
    final rows = (result.data as Map)['orders'] as List? ?? const [];
    return [for (final r in rows) CustomerOrder.fromJson(Map<String, dynamic>.from(r as Map))];
  }

  Future<void> cancel(String orderId) async {
    await _functions.httpsCallable('storefront-cancelMyOrder').call({'orderId': orderId});
    changes.value++;
  }
}

/// Random 32-char hex id (128 bits) for idempotent requests.
String newRequestId() {
  final r = Random.secure();
  return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}
