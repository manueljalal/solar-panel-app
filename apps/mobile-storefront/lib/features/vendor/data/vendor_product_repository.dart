import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../home/domain/home_product.dart';
import '../domain/vendor_product_input.dart';

/// A product paired with its Firestore document id — HomeProduct alone
/// (the storefront's read-side display model) has no id, since shoppers
/// never need to reference a specific doc; a vendor editing/deleting
/// their own listing does.
class VendorOwnedProduct {
  const VendorOwnedProduct({required this.id, required this.product});
  final String id;
  final HomeProduct product;
}

/// Vendor-side product management. Writes go through the deployed Cloud
/// Functions (vendor-createProduct/updateProduct/deleteProduct) — never
/// directly to Firestore — because ownership checks (a vendor can only
/// touch their OWN products) need a server-side get() per write that
/// Firestore rules alone can't do cheaply. Reads (this vendor's own
/// product list) go direct to Firestore, which is fine: rules already
/// allow public read on `products`, and filtering by vendorId client-side
/// is just as valid as it is for any shopper's query.
class VendorProductRepository {
  VendorProductRepository({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  Stream<List<VendorOwnedProduct>> watchOwnProducts(String vendorId) {
    return _db
        .collection('products')
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => VendorOwnedProduct(id: d.id, product: HomeProduct.fromFirestore(d.data(), vendorName: '')))
            .toList());
  }

  Future<String> create(VendorProductInput input) async {
    final callable = _functions.httpsCallable('vendor-createProduct');
    final result = await callable.call(input.toJson());
    return result.data['productId'] as String;
  }

  Future<void> update(String productId, Map<String, dynamic> patch) async {
    final callable = _functions.httpsCallable('vendor-updateProduct');
    await callable.call({'productId': productId, 'patch': patch});
  }

  Future<void> delete(String productId) async {
    final callable = _functions.httpsCallable('vendor-deleteProduct');
    await callable.call({'productId': productId});
  }
}
