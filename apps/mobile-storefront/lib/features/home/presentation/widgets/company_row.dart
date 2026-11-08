import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/placeholder_image.dart';
import '../../../../shared/widgets/view_all_tile.dart';
import '../../domain/home_company.dart';
import '../company_store_screen.dart';

/// Compact company directory: rounded landscape logo tiles with the name underneath — the
/// same look as the bulk marketplace's company row. HomeScreen passes live
/// Firestore data once it has loaded. Tapping a company opens its store.
/// Shows [visible] companies; beyond that the last tile is "View all",
/// which opens every company in a grid — the row never grows endless.
class CompanyRow extends StatelessWidget {
  const CompanyRow({super.key, required this.companies});

  final List<HomeCompany> companies;

  static const height = 92.0;
  static const visible = 5;

  @override
  Widget build(BuildContext context) {
    final overflow = companies.length > visible + 1;
    final shown = overflow ? companies.take(visible).toList() : companies;
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: shown.length + (overflow ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (context, i) => i < shown.length
            ? CompanyTile(company: shown[i])
            : ViewAllTile(
                count: companies.length,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AllCompaniesScreen(
                      itemCount: companies.length,
                      itemBuilder: (context, i) => CompanyTile(company: companies[i]),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class CompanyTile extends StatelessWidget {
  const CompanyTile({super.key, required this.company});

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
        width: 92,
        child: Column(
          children: [
            // Landscape tile: logos (usually wider than tall) fit better.
            Container(
              width: 92,
              height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
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
