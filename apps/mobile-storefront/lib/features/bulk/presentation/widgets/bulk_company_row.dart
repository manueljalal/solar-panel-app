import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/placeholder_image.dart';
import '../../domain/bulk_models.dart';

/// One company that has at least one post in the current feed.
class BulkCompany {
  const BulkCompany({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.country,
    required this.postCount,
  });

  final String id;
  final String name;
  final String logoUrl;
  final BulkCountry country;
  final int postCount;
}

/// Distinct companies behind [posts], most active first. [logos] maps
/// vendorId -> logo URL from the vendor records (what Home's Companies row
/// uses); it fills in companies whose posts predate logos being saved on
/// posts.
List<BulkCompany> companiesOf(Iterable<BulkPost> posts, {Map<String, String> logos = const {}}) {
  final byId = <String, List<BulkPost>>{};
  for (final p in posts) {
    if (p.vendorId.isEmpty) continue;
    byId.putIfAbsent(p.vendorId, () => []).add(p);
  }
  final list = [
    for (final e in byId.entries)
      BulkCompany(
        id: e.key,
        name: e.value.first.businessName,
        logoUrl: e.value
            .map((p) => p.logoUrl)
            .firstWhere((u) => u.isNotEmpty, orElse: () => logos[e.key] ?? ''),
        country: e.value.first.country,
        postCount: e.value.length,
      ),
  ]..sort((a, b) => b.postCount.compareTo(a.postCount));
  return list;
}

/// Compact company directory: round logos with the name underneath. Tapping
/// one filters the feed to that company.
class BulkCompanyRow extends StatelessWidget {
  const BulkCompanyRow({
    super.key,
    required this.companies,
    required this.selectedId,
    required this.onSelected,
  });

  final List<BulkCompany> companies;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: companies.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (context, i) {
          final c = companies[i];
          final selected = selectedId == c.id;
          return InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.md),
            onTap: () => onSelected(selected ? null : c.id),
            child: SizedBox(
              width: 64,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.line,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: c.logoUrl.isEmpty
                        ? Center(
                            child: Text(
                              c.name.trim().isEmpty
                                  ? '?'
                                  : c.name
                                        .trim()
                                        .characters
                                        .first
                                        .toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          )
                        : NetworkImageWithFallback(
                            url: c.logoUrl,
                            fallbackIcon: Icons.storefront_outlined,
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMuted.copyWith(
                      fontSize: 11.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.primary : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
