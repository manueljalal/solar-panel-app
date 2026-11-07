import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/category_tabs.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/iraq_cities.dart';
import '../../../shared/widgets/city_picker.dart';
import '../data/home_repository.dart';
import '../domain/home_banner.dart';
import '../domain/home_category.dart';
import '../domain/home_company.dart';
import '../domain/home_product.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/company_row.dart';
import 'widgets/featured_masonry.dart';
import 'widgets/filter_chip_row.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/home_search_field.dart';
import 'widgets/product_tile.dart';
import 'widgets/skeletons.dart';
import 'widgets/section_header.dart';

/// Marketplace home — a dense, info-first layout rather than
/// hero-banner-then-uniform-card-grid. Specifically:
///  - a mixed-size featured grid (one large tile + two stacked small ones)
///    instead of a uniform NxN grid — see widgets/featured_masonry.dart
///  - a full-bleed banner that touches the search bar above it, no
///    floating card margin — see widgets/banner_carousel.dart
///  - dense product rows with a rating+sold-count line baked into the
///    row, not just price below an image — see widgets/product_row.dart
/// No auth wall — browsing works as a guest from the first frame.
///
/// Companies and products load live from Firestore via [HomeRepository].
/// While loading, each section shows a skeleton; on a read error it shows a
/// retry prompt; an empty companies collection hides that section. There is
/// no sample/fallback data in production.
///
/// This file only composes the section widgets; each section's own logic
/// and styling lives in presentation/widgets/, and its placeholder/fallback
/// data in domain/. Keep it that way — this file grew to 700+ lines in
/// earlier iterations by accumulating private widget classes here instead
/// of splitting them out as they were added.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, HomeRepository? repository})
    : _repository = repository;

  final HomeRepository? _repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeRepository _repository =
      widget._repository ?? HomeRepository();

  // null = still loading. Never pre-filled with sample data.
  List<HomeCompany>? _companies;
  List<HomeProduct>? _products;
  List<HomeBanner> _banners = const [];
  List<HomeCategory> _categories = const [];
  String? _selectedCategory; // null = all
  ProductSort _sort = ProductSort.bestSelling;
  String? _companyCity; // IraqCity id; null = all cities
  bool _companiesFailed = false;
  bool _productsFailed = false;

  @override
  void initState() {
    super.initState();
    _loadLiveData();
  }

  /// Companies and products load independently so one failing (or being
  /// slow) doesn't block or blank the other.
  void _loadLiveData() {
    setState(() {
      _companies = null;
      _products = null;
      _companiesFailed = false;
      _productsFailed = false;
    });
    _repository
        .fetchCompanies(refresh: true)
        .then(
          (value) {
            if (mounted) setState(() => _companies = value);
          },
          onError: (_) {
            if (mounted) setState(() => _companiesFailed = true);
          },
        );
    // No banners (or a failed read) simply means no carousel — never a
    // hardcoded stand-in.
    _repository.fetchBanners().then((value) {
      if (mounted) setState(() => _banners = value);
    }, onError: (_) {});
    // Categories are a nicety — if they fail to load the row just hides.
    _repository.fetchCategories().then((value) {
      if (mounted) setState(() => _categories = value);
    }, onError: (_) {});
    _loadProducts();
  }

  void _loadProducts() {
    final requested = _selectedCategory;
    setState(() {
      _products = null;
      _productsFailed = false;
    });
    _repository
        .fetchProducts(categoryId: requested)
        .then(
          (value) {
            // Ignore a stale response if the user switched category meanwhile.
            if (mounted && requested == _selectedCategory)
              setState(() => _products = value);
          },
          onError: (_) {
            if (mounted && requested == _selectedCategory)
              setState(() => _productsFailed = true);
          },
        );
  }

  void _selectCategory(String? id) {
    if (id == _selectedCategory) return;
    _selectedCategory = id;
    _loadProducts();
  }

  Widget _error(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(l10n.homeLoadError, style: AppTypography.bodyMuted),
          ),
          TextButton(onPressed: _loadLiveData, child: Text(l10n.retry)),
        ],
      ),
    );
  }

  Widget _companiesSection(AppLocalizations l10n) {
    if (_companiesFailed) return _error(l10n);
    final companies = _companies;
    if (companies == null) return const CompanyRowSkeleton();
    final city = iraqCityById(_companyCity);
    if (city == null) return CompanyRow(companies: companies);
    final inCity = companies.where((c) => matchIraqCity(c.city)?.id == city.id).toList();
    if (inCity.isEmpty) {
      final lang = Localizations.localeOf(context).languageCode;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(l10n.companiesNoneInCity(city.nameFor(lang)), style: AppTypography.bodyMuted),
      );
    }
    return CompanyRow(companies: inCity);
  }

  Future<void> _pickCompanyCity() async {
    final counts = <String, int>{};
    for (final c in _companies ?? const <HomeCompany>[]) {
      final id = matchIraqCity(c.city)?.id;
      if (id != null) counts[id] = (counts[id] ?? 0) + 1;
    }
    final picked = await showIraqCityPicker(context, selectedId: _companyCity, counts: counts, allowAll: true);
    if (picked == null || !mounted) return;
    setState(() {
      _companyCity = picked.isEmpty ? null : picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final products = sortProducts(_products ?? const <HomeProduct>[], _sort);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const HomeAppBar(),
                  const SizedBox(height: AppSpacing.md),
                  const HomeSearchField(),
                ]),
              ),
            ),
            if (_banners.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
              // Keyed by the banner ids so an updated set rebuilds the pager.
              SliverToBoxAdapter(
                child: BannerCarousel(
                  key: ValueKey(_banners.map((b) => b.id).join(',')),
                  banners: _banners,
                ),
              ),
            ],
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (!(_companies?.isEmpty ?? false)) ...[
                    SectionHeader(
                      title: l10n.sectionCompanies,
                      trailing: CityFilterChip(
                        label: iraqCityById(_companyCity)?.nameFor(Localizations.localeOf(context).languageCode) ?? l10n.cityAll,
                        active: _companyCity != null,
                        onTap: _pickCompanyCity,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _companiesSection(l10n),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  SectionHeader(title: l10n.sectionFeatured),
                  const SizedBox(height: AppSpacing.md),
                  const FeaturedMasonry(),
                  const SizedBox(height: AppSpacing.xl),
                  if (_categories.isNotEmpty) ...[
                    CategoryTabs(
                      categories: _categories,
                      selectedId: _selectedCategory,
                      onSelected: _selectCategory,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.sectionBestSellers,
                        style: AppTypography.sectionTitle,
                      ),
                      SortButton(
                        value: _sort,
                        onChanged: (s) => setState(() => _sort = s),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ]),
              ),
            ),
            if (_productsFailed)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverToBoxAdapter(child: _error(l10n)),
              )
            else if (_products == null)
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverToBoxAdapter(child: ProductGridSkeleton()),
              ),
            if (_products != null && products.isEmpty && !_productsFailed)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    child: Text(
                      l10n.categoryNoProducts,
                      style: AppTypography.bodyMuted,
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverGrid(
                // Square photo (full tile width) + a fixed text block.
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.lg,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisExtent: ProductTile.extentFor(
                    (MediaQuery.of(context).size.width -
                            AppSpacing.lg * 2 -
                            AppSpacing.md) /
                        2,
                  ),
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => ProductTile(product: products[i]),
                  childCount: products.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
        ),
      ),
    );
  }
}
