import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/placeholder_image.dart';
import '../../../product/presentation/product_detail_screen.dart';
import '../../domain/home_product.dart';

/// Grid tile for Best sellers — same plain look as the bulk marketplace: a
/// square photo with a hairline border, then title, price, and one muted
/// line with the vendor and rating. No card background, shadow or badges.
/// Tapping it opens the product detail screen.
class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.product});

  /// Height of everything under the square photo.
  static const _textBlock = 78.0;

  /// Grid row height for a tile of [tileWidth] (square photo + text).
  static double extentFor(double tileWidth) => tileWidth + _textBlock;

  final HomeProduct product;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.card),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: NetworkImageWithFallback(
                url: product.imageUrl,
                fallbackIcon: Icons.solar_power_outlined,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.titleFor(lang),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.cardTitle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            product.price,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  product.vendor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMuted.copyWith(fontSize: 12),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.star, size: 12, color: AppColors.accent),
              const SizedBox(width: 2),
              Text(
                '${product.rating}',
                style: AppTypography.bodyMuted.copyWith(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
