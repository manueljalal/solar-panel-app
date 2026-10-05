import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/home_company.dart';
import '../domain/home_product.dart';

/// Reads live Companies/Products data for the home screen from Firestore.
/// Errors propagate to the caller (no fake fallback data) so the UI can show
/// a real error state instead of presenting made-up vendors as real ones. An
/// empty collection returns an empty list.
class HomeRepository {
  HomeRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<List<HomeCompany>> fetchCompanies() async {
    final snapshot = await _db.collection('vendors').orderBy('rating', descending: true).get();
    return snapshot.docs.map((d) => HomeCompany.fromFirestore(d.data())).toList();
  }

  Future<List<HomeProduct>> fetchProducts() async {
    final snapshot = await _db.collection('products').orderBy('sold', descending: true).get();
    if (snapshot.docs.isEmpty) return [];

    // Products store vendorId, not a display name — resolve names in one
    // batch read against `vendors` rather than one lookup per product.
    final vendorIds = snapshot.docs.map((d) => d.data()['vendorId'] as String?).whereType<String>().toSet();
    final vendorNames = <String, String>{};
    for (final id in vendorIds) {
      final doc = await _db.collection('vendors').doc(id).get();
      vendorNames[id] = doc.data()?['businessName'] as String? ?? 'Unknown vendor';
    }

    return snapshot.docs.map((d) {
      final data = d.data();
      final vendorId = data['vendorId'] as String?;
      return HomeProduct.fromFirestore(data, vendorName: vendorNames[vendorId] ?? 'Unknown vendor');
    }).toList();
  }
}
