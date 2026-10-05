import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/placeholder_image.dart';
import '../../domain/home_company.dart';

/// Horizontal-scroll row of vendor tiles for the "Companies" section.
/// HomeScreen passes live Firestore data once it has loaded.
class CompanyRow extends StatelessWidget {
  const CompanyRow({super.key, required this.companies});

  final List<HomeCompany> companies;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 172,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: companies.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (context, i) => _CompanyTile(company: companies[i]),
      ),
    );
  }
}

class _CompanyTile extends StatelessWidget {
  const _CompanyTile({required this.company});

  final HomeCompany company;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              boxShadow: AppShadows.card,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              child: SizedBox(
                width: 96,
                height: 96,
                child: NetworkImageWithFallback(url: company.logoUrl, fallbackIcon: Icons.storefront_outlined),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            company.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.cardTitle,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(company.city, style: AppTypography.bodyMuted, overflow: TextOverflow.ellipsis),
              ),
              const Icon(Icons.star, size: 12, color: AppColors.accent),
              const SizedBox(width: 2),
              Text('${company.rating}', style: AppTypography.bodyMuted),
            ],
          ),
        ],
      ),
    );
  }
}
