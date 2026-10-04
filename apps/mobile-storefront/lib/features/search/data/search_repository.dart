import '../../home/data/home_repository.dart';
import '../../home/domain/home_product.dart';

/// Client-side filter search over the product catalog. Firestore has no
/// native substring text search, and at 4 seeded products a real search
/// index (Algolia/Typesense/Firestore's own array-contains tricks) is
/// overkill — this fetches the live product list via HomeRepository (same
/// source of truth as the home screen) and filters in memory. Revisit
/// once the catalog is large enough that "fetch everything" stops being
/// reasonable.
class SearchRepository {
  SearchRepository({HomeRepository? homeRepository}) : _homeRepository = homeRepository ?? HomeRepository();

  final HomeRepository _homeRepository;

  Future<List<HomeProduct>> search(String query) async {
    final products = await _homeRepository.fetchProducts();
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return products;

    return products.where((p) {
      return p.title.toLowerCase().contains(normalized) ||
          p.brand.toLowerCase().contains(normalized) ||
          p.spec.toLowerCase().contains(normalized) ||
          p.vendor.toLowerCase().contains(normalized);
    }).toList();
  }
}
