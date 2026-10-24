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
  FakeHomeRepository({this.withBanners = false});

  /// Banners are off by default: the carousel auto-advances on a timer,
  /// which only the carousel test needs.
  final bool withBanners;

  @override
  Future<List<HomeCompany>> fetchCompanies({bool refresh = false}) async => homeCompanies;

  @override
  Future<List<HomeBanner>> fetchBanners() async => withBanners ? homeBanners : const [];

  @override
  Future<List<HomeCategory>> fetchCategories() async => const [];

  @override
  Future<List<HomeProduct>> fetchProducts({String? categoryId}) async => homeProducts;

  @override
  Future<List<HomeProduct>> fetchProductsByVendor(HomeCompany vendor) async =>
      homeProducts.where((p) => p.vendor == vendor.name).toList();
}
