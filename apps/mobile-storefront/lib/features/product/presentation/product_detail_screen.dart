import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../cart/data/cart_scope.dart';
import '../../home/domain/home_product.dart';
import 'widgets/product_action_bar.dart';
import 'widgets/product_image_header.dart';
import 'widgets/product_spec_row.dart';
import 'widgets/product_vendor_row.dart';
import 'widgets/quote_request_sheet.dart';

/// Product detail — reached by tapping a row in the storefront home's
/// "Best sellers" list. Shows the photo, spec strip, price, description,
/// and the two real actions (request a quote or add to cart).
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});

  final HomeProduct product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProductImageHeader(
                      imageUrl: product.imageUrl,
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${product.spec} · ${product.brand}', style: AppTypography.eyebrow),
                          const SizedBox(height: 4),
                          Text(product.title, style: AppTypography.h1.copyWith(fontSize: 22)),
                          const SizedBox(height: 8),
                          ProductVendorRow(vendor: product.vendor, rating: product.rating, sold: product.sold),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(product.price, style: AppTypography.h1.copyWith(fontSize: 26)),
                              const SizedBox(width: 8),
                              Text(l10n.perUnit, style: AppTypography.bodyMuted),
                              const Spacer(),
                              _StockPill(inStock: product.inStock),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadii.card),
                              boxShadow: AppShadows.card,
                            ),
                            child: ProductSpecRow(
                              specs: [
                                ProductSpec(product.spec, l10n.specPower),
                                if (product.warranty != null) ProductSpec(product.warranty!, l10n.specWarranty),
                                ProductSpec(product.brand, l10n.specBrand),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(l10n.description, style: AppTypography.sectionTitle.copyWith(fontSize: 16)),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            product.description ?? l10n.noDescriptionYet,
                            style: AppTypography.body.copyWith(color: AppColors.ink600, height: 1.55),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ProductActionBar(
              onRequestQuote: () => showQuoteRequestSheet(context, product),
              onAddToCart: () {
                CartScope.of(context).add(product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.addedToCart(product.title))),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StockPill extends StatelessWidget {
  const _StockPill({required this.inStock});

  final bool inStock;

  @override
  Widget build(BuildContext context) {
    final color = inStock ? AppColors.success : AppColors.warning;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Text(
        inStock ? l10n.inStock : l10n.outOfStock,
        style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}
