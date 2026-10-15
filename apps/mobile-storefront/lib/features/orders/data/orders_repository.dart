import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../../cart/domain/cart_item.dart';
import '../domain/order.dart';

/// Delivery details collected at checkout.
class DeliveryDetails {
  const DeliveryDetails({required this.name, required this.phone, required this.city, required this.address, this.note = ''});

  final String name;
  final String phone;
  final String city;
  final String address;
  final String note;
}

/// All order traffic goes through Cloud Functions — `orders` isn't
/// client-readable in firestore.rules (it holds contact details), and
/// prices are always re-read server-side.
class OrdersRepository {
  OrdersRepository({FirebaseFunctions? functions, FirebaseFirestore? firestore})
      : _functions = functions ?? FirebaseFunctions.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFunctions _functions;
  final FirebaseFirestore _db;

  /// Bumped after anything that changes the caller's orders, so an
  /// already-built Orders tab knows to reload.
  static final changes = ValueNotifier<int>(0);

  /// Delivery fee per currency from settings/platform (public doc). Shown
  /// at checkout for information; the server applies the real one.
  Future<Map<String, double>> fetchDeliveryFees() async {
    final data = (await _db.collection('settings').doc('platform').get()).data() ?? const {};
    final fee = data['deliveryFee'];
    return {
      'USD': fee is Map ? (fee['USD'] as num?)?.toDouble() ?? 0 : 0,
      'IQD': fee is Map ? (fee['IQD'] as num?)?.toDouble() ?? 0 : 0,
    };
  }

  /// A fresh id per checkout attempt. Reusing it on retry (same screen)
  /// makes the server return the first attempt's orders instead of placing
  /// them twice.
  static String newCheckoutId() {
    final r = Random.secure();
    String hex(int n) => List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
    return '${hex(8)}-${hex(4)}-${hex(4)}-${hex(4)}-${hex(12)}';
  }

  Future<List<String>> placeOrder({
    required String checkoutId,
    required List<CartItem> items,
    required DeliveryDetails delivery,
  }) async {
    final result = await _functions.httpsCallable('storefront-placeOrder').call({
      'checkoutId': checkoutId,
      'items': [for (final i in items) {'productId': i.product.id, 'quantity': i.quantity}],
      'contact': {'name': delivery.name, 'phone': delivery.phone},
      'address': {'text': delivery.address, 'city': delivery.city},
      'note': delivery.note,
      'paymentMethod': 'cod',
    });
    changes.value++;
    return [for (final id in (result.data['orderIds'] as List)) '$id'];
  }

  Future<List<CustomerOrder>> listMyOrders() async {
    final result = await _functions.httpsCallable('storefront-listMyOrders').call();
    final list = (result.data['orders'] as List?) ?? const [];
    return [for (final o in list) CustomerOrder.fromJson(Map<String, dynamic>.from(o as Map))];
  }

  Future<void> cancel(String orderId) => _updateStatus(orderId, OrderStatus.cancelled);

  Future<void> confirmInstallation(String orderId) => _updateStatus(orderId, OrderStatus.installedVerified);

  Future<void> _updateStatus(String orderId, OrderStatus status) async {
    await _functions.httpsCallable('storefront-updateMyOrder').call({'orderId': orderId, 'status': status.wire});
    changes.value++;
  }

  Future<void> submitReview({required String orderId, required String productId, required int rating, String comment = ''}) async {
    await _functions.httpsCallable('storefront-submitReview').call({
      'orderId': orderId,
      'productId': productId,
      'rating': rating,
      'comment': comment,
    });
    changes.value++;
  }

  Future<void> openDispute({required String orderId, required String reason}) async {
    await _functions.httpsCallable('storefront-openDispute').call({'orderId': orderId, 'reason': reason});
    changes.value++;
  }

  Future<List<QuoteRequestSummary>> listMyQuoteRequests() async {
    final result = await _functions.httpsCallable('storefront-listMyQuoteRequests').call();
    final list = (result.data['requests'] as List?) ?? const [];
    return [for (final r in list) QuoteRequestSummary.fromJson(Map<String, dynamic>.from(r as Map))];
  }
}
