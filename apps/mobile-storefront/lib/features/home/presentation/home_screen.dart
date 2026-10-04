import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../data/home_repository.dart';
import '../domain/home_company.dart';
import '../domain/home_product.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/company_row.dart';
import 'widgets/featured_masonry.dart';
import 'widgets/filter_chip_row.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/home_search_field.dart';
import 'widgets/product_row.dart';
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
/// Companies and products load live from Firestore via [HomeRepository];
/// the hardcoded lists in domain/ are the fallback shown while loading and
/// on any read error, so the screen never renders blank.
///
/// This file only composes the section widgets; each section's own logic
/// and styling lives in presentation/widgets/, and its placeholder/fallback
/// data in domain/. Keep it that way — this file grew to 700+ lines in
/// earlier iterations by accumulating private widget classes here instead
/// of splitting them out as they were added.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, HomeRepository? repository}) : _repository = repository;

  final HomeRepository? _repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeRepository _repository = widget._repository ?? HomeRepository();

  List<HomeCompany> _companies = homeCompanies;
  List<HomeProduct> _products = homeProducts;

  @override
  void initState() {
    super.initState();
    _loadLiveData();
  }

  Future<void> _loadLiveData() async {
    final results = await Future.wait([_repository.fetchCompanies(), _repository.fetchProducts()]);
    if (!mounted) return;
    setState(() {
      _companies = results[0] as List<HomeCompany>;
      _products = results[1] as List<HomeProduct>;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const HomeAppBar(),
                  const SizedBox(height: AppSpacing.md),
                  const HomeSearchField(),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            const SliverToBoxAdapter(child: BannerCarousel()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SectionHeader(title: l10n.sectionCompanies),
                  const SizedBox(height: AppSpacing.md),
                  CompanyRow(companies: _companies),
                  const SizedBox(height: AppSpacing.xl),
                  SectionHeader(title: l10n.sectionFeatured),
                  const SizedBox(height: AppSpacing.md),
                  const FeaturedMasonry(),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.sectionBestSellers, style: AppTypography.sectionTitle),
                      const FilterChipRow(),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: ProductRow(product: _products[i]),
                  ),
                  childCount: _products.length,
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
