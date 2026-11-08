import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';

/// Last tile of a company row when there are more companies than fit:
/// the same 92×62 rounded tile as a company, opening the full list.
class ViewAllTile extends StatelessWidget {
  const ViewAllTile({super.key, required this.count, required this.onTap});

  /// Total number of companies, shown in the tile.
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: 92,
        child: Column(
          children: [
            Container(
              width: 92,
              height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.primarySoft,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.grid_view_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count',
                    style: AppTypography.body.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.companiesViewAll,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMuted.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen grid of company tiles behind a "View all" tile.
class AllCompaniesScreen extends StatelessWidget {
  const AllCompaniesScreen({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSunken,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.companiesAllTitle,
          style: AppTypography.h1.copyWith(fontSize: 19),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 120,
          mainAxisExtent: 98,
          mainAxisSpacing: 16,
          crossAxisSpacing: 8,
        ),
        itemCount: itemCount,
        itemBuilder: (context, i) => Center(child: itemBuilder(context, i)),
      ),
    );
  }
}
