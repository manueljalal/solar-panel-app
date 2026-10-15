import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/placeholder_image.dart';
import '../data/home_repository.dart';
import '../domain/home_company.dart';
import '../domain/home_product.dart';
import 'widgets/product_tile.dart';

/// A company's own store: its logo/name/city/rating on top and every
/// product that vendor sells below. Reached by tapping a tile in the home
/// screen's Companies row. Products are read live from Firestore, filtered
/// server-side by vendorId.
class CompanyStoreScreen extends StatefulWidget {
  const CompanyStoreScreen({
    super.key,
    required this.company,
    HomeRepository? repository,
  }) : _repository = repository;

  final HomeCompany company;
  final HomeRepository? _repository;

  @override
  State<CompanyStoreScreen> createState() => _CompanyStoreScreenState();
}

class _CompanyStoreScreenState extends State<CompanyStoreScreen> {
  late final HomeRepository _repository =
      widget._repository ?? HomeRepository();
  late Future<List<HomeProduct>> _products = _repository.fetchProductsByVendor(
    widget.company,
  );

  void _retry() => setState(
    () => _products = _repository.fetchProductsByVendor(widget.company),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final company = widget.company;
    final name = company.name.trim();
    final tileWidth =
        (MediaQuery.of(context).size.width -
            AppSpacing.lg * 2 -
            AppSpacing.md) /
        2;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          company.name,
          style: AppTypography.sectionTitle.copyWith(fontSize: 17),
        ),
      ),
      body: FutureBuilder<List<HomeProduct>>(
        future: _products,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState != ConnectionState.done;
          final products = snapshot.data ?? const <HomeProduct>[];

          Widget? status;
          if (snapshot.hasError) {
            status = Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.homeLoadError,
                    style: AppTypography.bodyMuted,
                  ),
                ),
                TextButton(onPressed: _retry, child: Text(l10n.retry)),
              ],
            );
          } else if (loading) {
            status = const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (products.isEmpty) {
            status = Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  l10n.companyNoProducts,
                  style: AppTypography.bodyMuted,
                ),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.line),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: company.logoUrl.isEmpty
                            ? Center(
                                child: Text(
                                  name.isEmpty
                                      ? '?'
                                      : name.characters.first.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 24,
                                  ),
                                ),
                              )
                            : NetworkImageWithFallback(
                                url: company.logoUrl,
                                fallbackIcon: Icons.storefront_outlined,
                              ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              company.name,
                              style: AppTypography.cardTitle.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (company.city.isNotEmpty) ...[
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: AppColors.ink600,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    company.city,
                                    style: AppTypography.bodyMuted,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                ],
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${company.rating}',
                                  style: AppTypography.bodyMuted,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (status != null)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  sliver: SliverToBoxAdapter(child: status),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.lg,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisExtent: ProductTile.extentFor(tileWidth),
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => ProductTile(product: products[i]),
                      childCount: products.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
