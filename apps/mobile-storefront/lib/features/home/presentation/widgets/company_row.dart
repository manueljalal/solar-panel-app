import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/placeholder_image.dart';
import '../../domain/home_company.dart';
import '../company_store_screen.dart';

/// Compact company directory: round logos with the name underneath — the
/// same look as the bulk marketplace's company row. HomeScreen passes live
/// Firestore data once it has loaded. Tapping a company opens its store.
class CompanyRow extends StatelessWidget {
  const CompanyRow({super.key, required this.companies});

  final List<HomeCompany> companies;

  static const height = 92.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
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
    final name = company.name.trim();
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.md),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CompanyStoreScreen(company: company)),
      ),
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
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
                          fontSize: 19,
                        ),
                      ),
                    )
                  : NetworkImageWithFallback(
                      url: company.logoUrl,
                      fallbackIcon: Icons.storefront_outlined,
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              company.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMuted.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
