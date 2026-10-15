import 'package:solary_marketplace/features/home/data/home_repository.dart';
import 'package:solary_marketplace/features/home/domain/home_banner.dart';
import 'package:solary_marketplace/features/home/domain/home_category.dart';
import 'package:solary_marketplace/features/home/domain/home_company.dart';
import 'package:solary_marketplace/features/home/domain/home_product.dart';

import 'home_fixtures.dart';

/// A HomeRepository that never touches Firestore — returns the same
/// fixture content, so widget tests render the same deterministic data
/// regardless of network/Firebase-init state.
class FakeHomeRepository implements HomeRepository {
  FakeHomeRepository({this.banners = const []});

  final List<HomeBanner> banners;

  @override
  Future<List<HomeCompany>> fetchCompanies({bool refresh = false}) async => homeCompanies;

  @override
  Future<List<HomeProduct>> fetchProducts({String? categoryId}) async => homeProducts;

  @override
  Future<List<HomeProduct>> fetchProductsByVendor(HomeCompany vendor) async =>
      homeProducts.where((p) => p.vendorId == vendor.id).toList();

  @override
  Future<List<HomeBanner>> fetchBanners() async => banners;

  @override
  Future<List<HomeCategory>> fetchCategories() async => const [];
}
