import 'package:solary_marketplace/features/home/data/home_repository.dart';
import 'package:solary_marketplace/features/home/domain/home_company.dart';
import 'package:solary_marketplace/features/home/domain/home_product.dart';

import 'home_fixtures.dart';

/// A HomeRepository that never touches Firestore — returns the same
/// fixture content, so widget tests render the same deterministic data
/// regardless of network/Firebase-init state.
class FakeHomeRepository implements HomeRepository {
  @override
  Future<List<HomeCompany>> fetchCompanies() async => homeCompanies;

  @override
  Future<List<HomeProduct>> fetchProducts() async => homeProducts;
}
