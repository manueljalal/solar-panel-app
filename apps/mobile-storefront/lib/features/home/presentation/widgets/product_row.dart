import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/placeholder_image.dart';
import '../../../product/presentation/product_detail_screen.dart';
import '../../domain/home_product.dart';

/// Dense list-style row (not a card in a grid) — image, spec/brand
/// eyebrow, title, vendor, then a rating+sold line baked directly into
/// the row like a real marketplace listing, with price pinned to the
/// trailing edge. Closer to how Alibaba/Amazon actually lay out results
/// than a Pinterest-style photo grid. Tapping it opens the product detail
/// screen.
class ProductRow extends StatelessWidget {
  const ProductRow({super.key, required this.product});

  final HomeProduct product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppSpacing.sm)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  child: SizedBox(
                    width: 92,
                    height: 92,
                    child: NetworkImageWithFallback(url: product.imageUrl, fallbackIcon: Icons.solar_power_outlined),
                  ),
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
                    const SizedBox(height: 2),
                    Text(product.vendor, style: AppTypography.bodyMuted, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 13, color: AppColors.accent),
                        const SizedBox(width: 2),
                        Text(
                          '${product.rating}',
                          style: AppTypography.bodyMuted.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(color: AppColors.ink400, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(l10n.productSold(product.sold), style: AppTypography.bodyMuted),
                        const Spacer(),
                        const Icon(Icons.favorite_border, size: 17, color: AppColors.ink400),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(product.price, style: AppTypography.price),
            ],
          ),
        ),
      ),
    );
  }
}
