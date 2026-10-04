import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// The "sold by X · ★ rating" line under the product title — tapping it
/// will eventually open the vendor's storefront page.
class ProductVendorRow extends StatelessWidget {
  const ProductVendorRow({super.key, required this.vendor, required this.rating, required this.sold});

  final String vendor;
  final double rating;
  final int sold;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Row(
        children: [
          Text(vendor, style: AppTypography.link),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.accent),
          const Spacer(),
          const Icon(Icons.star, size: 14, color: AppColors.accent),
          const SizedBox(width: 3),
          Text('$rating', style: AppTypography.bodyMuted.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Text('($sold)', style: AppTypography.bodyMuted),
        ],
      ),
    );
  }
}
