import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/home_banner.dart';
import '../domain/home_category.dart';
import '../domain/home_company.dart';
import '../domain/home_product.dart';

/// Reads live Companies/Products data from Firestore.
/// Errors propagate to the caller (no fake fallback data) so the UI can show
/// a real error state instead of presenting made-up vendors as real ones. An
/// empty collection returns an empty list.
class HomeRepository {
  HomeRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // Bounded reads — the home screen never needs the whole catalog, and an
  // unbounded query gets slower and costlier with every product added.
  static const _maxCompanies = 50;
  static const _maxProducts = 50;

  // One shared in-flight/finished companies read: the Companies row and the
  // product list's vendor-name lookup both need it, so the home screen makes
  // a single vendors query instead of one plus a follow-up per product batch.
  Future<List<HomeCompany>>? _companiesRead;

  Future<List<HomeCompany>> fetchCompanies({bool refresh = false}) {
    if (refresh || _companiesRead == null) {
      final read = _readCompanies();
      _companiesRead = read;
      // A failed read must not stay cached, or retry would just re-throw it.
      read.catchError((_) {
        if (identical(_companiesRead, read)) _companiesRead = null;
        return <HomeCompany>[];
      });
    }
    return _companiesRead!;
  }

  Future<List<HomeCompany>> _readCompanies() async {
    final snapshot = await _db
        .collection('vendors')
        .orderBy('rating', descending: true)
        .limit(_maxCompanies)
        .get();
    return snapshot.docs
        .map((d) => HomeCompany.fromFirestore(d.id, d.data()))
        .toList();
  }

  /// Promo carousel slides, oldest first (the order the admin added them).
  /// The admin tool caps this at 5; the limit here is a second guard.
  Future<List<HomeBanner>> fetchBanners() async {
    final snapshot = await _db.collection('banners').limit(5).get();
    final docs = snapshot.docs.toList()
      ..sort((a, b) {
        final ta = a.data()['createdAt'];
        final tb = b.data()['createdAt'];
        if (ta is Timestamp && tb is Timestamp) return ta.compareTo(tb);
        return 0;
      });
    return docs
        .map((d) => HomeBanner.fromFirestore(d.id, d.data()))
        .where((b) => b.imageUrl.isNotEmpty)
        .toList();
  }

  Future<List<HomeCategory>> fetchCategories() async {
    final snapshot = await _db.collection('categories').limit(100).get();
    final list =
        snapshot.docs
            .map((d) => HomeCategory.fromFirestore(d.id, d.data()))
            .toList()
          ..sort((a, b) => a.nameFor('en').compareTo(b.nameFor('en')));
    return list;
  }

  /// Best sellers, optionally restricted to one category. The filtered query
  /// skips orderBy (which would need a composite index) and sorts in memory.
  Future<List<HomeProduct>> fetchProducts({String? categoryId}) async {
    if (categoryId == null) {
      final snapshot = await _db
          .collection('products')
          .orderBy('sold', descending: true)
          .limit(_maxProducts)
          .get();
      return _withVendorNames(snapshot.docs);
    }
    final snapshot = await _db
        .collection('products')
        .where('category', isEqualTo: categoryId)
        .limit(_maxProducts)
        .get();
    final products = await _withVendorNames(snapshot.docs);
    products.sort((a, b) => b.sold.compareTo(a.sold));
    return products;
  }

  /// Every product a single vendor sells — the contents of that company's
  /// store page. No orderBy, to avoid needing a composite index; sorted
  /// in memory instead (a vendor's catalog is small).
  Future<List<HomeProduct>> fetchProductsByVendor(HomeCompany vendor) async {
    final snapshot = await _db
        .collection('products')
        .where('vendorId', isEqualTo: vendor.id)
        .limit(200)
        .get();
    final products =
        snapshot.docs
            .map(
              (d) =>
                  HomeProduct.fromFirestore(d.data(), vendorName: vendor.name),
            )
            .toList()
          ..sort((a, b) => b.sold.compareTo(a.sold));
    return products;
  }

  Future<List<HomeProduct>> _withVendorNames(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (docs.isEmpty) return [];

    // Vendor names come from the companies read the home screen already
    // makes (no extra round trip). Only vendors outside that list — rare —
    // get an individual lookup, in parallel.
    final known = {
      for (final c in await fetchCompanies().catchError((_) => <HomeCompany>[]))
        c.id: c.name,
    };
    final missing = docs
        .map((d) => d.data()['vendorId'] as String?)
        .whereType<String>()
        .toSet()
        .where((id) => !known.containsKey(id));
    final extra = await Future.wait(
      missing.map((id) async {
        final doc = await _db.collection('vendors').doc(id).get();
        return MapEntry(
          id,
          doc.data()?['businessName'] as String? ?? 'Unknown vendor',
        );
      }),
    );
    known.addEntries(extra);

    return docs.map((d) {
      final data = d.data();
      return HomeProduct.fromFirestore(
        data,
        vendorName: known[data['vendorId']] ?? 'Unknown vendor',
      );
    }).toList();
  }
}
