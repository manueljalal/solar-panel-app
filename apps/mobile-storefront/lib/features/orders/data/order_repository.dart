import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/auth/auth_repository.dart';
import '../../cart/domain/cart_item.dart';
import '../domain/order.dart';

class CheckoutDetails {
  const CheckoutDetails({
    required this.name,
    required this.phone,
    required this.city,
    required this.address,
    this.note = '',
  });

  final String name;
  final String phone;
  final String city;
  final String address;
  final String note;
}

/// Orders go through Cloud Functions for every write
/// (storefront-placeOrder / storefront-cancelOrder) — firestore.rules
/// refuses client writes to `orders`. Only ids and quantities are sent;
/// the server prices the order from `products`. Reads are a direct,
/// owner-scoped Firestore query (allowed by the rules' uid check).
class OrderRepository {
  OrderRepository({FirebaseFirestore? firestore, FirebaseFunctions? functions, AuthRepository? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _auth = auth ?? AuthRepository();

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final AuthRepository _auth;

  /// Returns the new order's id. Makes sure a (possibly anonymous) user
  /// exists first — main.dart's sign-in is fire-and-forget, so on a slow
  /// first launch it may not have finished yet.
  Future<String> placeOrder({required List<CartItem> items, required CheckoutDetails details}) async {
    if (await _auth.ensureSignedIn() == null) {
      throw FirebaseFunctionsException(code: 'unauthenticated', message: 'Sign in required.');
    }
    final result = await _functions.httpsCallable('storefront-placeOrder').call<Map<String, dynamic>>({
      'items': [
        for (final item in items) {'productId': item.product.id, 'quantity': item.quantity},
      ],
      'contact': {'name': details.name, 'phone': details.phone},
      'delivery': {'city': details.city, 'address': details.address, 'note': details.note},
    });
    return result.data['orderId'] as String;
  }

  Future<void> cancelOrder(String orderId) async {
    await _functions.httpsCallable('storefront-cancelOrder').call<Map<String, dynamic>>({'orderId': orderId});
  }

  /// Live list of the signed-in customer's orders, newest first. Uses the
  /// (uid, createdAt desc) index in firestore.indexes.json.
  Stream<List<CustomerOrder>> watchMyOrders(String uid) {
    return _db
        .collection('orders')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map((d) => CustomerOrder.fromFirestore(d.id, d.data())).toList());
  }
}
