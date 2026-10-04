import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/placeholder_image.dart';
import '../../data/vendor_product_repository.dart';

/// One row in the vendor's own product list — tap to edit, trailing icon
/// to delete. Shows stock status since that's the one field a vendor
/// checks at a glance that a shopper's row doesn't need.
class VendorProductListTile extends StatelessWidget {
  const VendorProductListTile({super.key, required this.owned, required this.onTap, required this.onDelete});

  final VendorOwnedProduct owned;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final product = owned.product;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: NetworkImageWithFallback(url: product.imageUrl, fallbackIcon: Icons.solar_power_outlined),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${product.spec} · ${product.brand}', style: AppTypography.eyebrow),
                    const SizedBox(height: 2),
                    Text(product.title, style: AppTypography.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(product.price, style: AppTypography.price.copyWith(fontSize: 14)),
                        const SizedBox(width: 8),
                        _StockPill(inStock: product.inStock),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.ink400),
                onPressed: onDelete,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadii.chip)),
      child: Text(
        inStock ? l10n.inStock : l10n.outOfStock,
        style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}
