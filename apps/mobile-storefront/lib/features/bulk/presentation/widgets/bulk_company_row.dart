import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/placeholder_image.dart';
import '../../../../shared/widgets/view_all_tile.dart';
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
List<BulkCompany> companiesOf(
  Iterable<BulkPost> posts, {
  Map<String, String> logos = const {},
}) {
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

/// Compact company directory: rounded landscape logo tiles with the name
/// underneath, the same look as Home's Companies row. Tapping one filters
/// the feed to that company.
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

  static const visible = 5;

  @override
  Widget build(BuildContext context) {
    // Five companies, then "View all". The selected one is always kept in
    // view, even if it came from the full list.
    final overflow = companies.length > visible + 1;
    var shown = companies;
    if (overflow) {
      final selected = companies.where((c) => c.id == selectedId);
      shown = [
        ...selected,
        ...companies.where((c) => c.id != selectedId),
      ].take(visible).toList();
    }
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: shown.length + (overflow ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (context, i) {
          if (i == shown.length) {
            return ViewAllTile(
              count: companies.length,
              onTap: () async {
                final picked = await Navigator.of(context).push<String>(
                  MaterialPageRoute(
                    builder: (_) => AllCompaniesScreen(
                      itemCount: companies.length,
                      itemBuilder: (context, i) => _tile(
                        context,
                        companies[i],
                        (id) => Navigator.of(context).pop(id ?? ''),
                      ),
                    ),
                  ),
                );
                // '' = the selected company was tapped again: clear the filter.
                if (picked != null) onSelected(picked.isEmpty ? null : picked);
              },
            );
          }
          return _tile(context, shown[i], (id) => onSelected(id));
        },
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    BulkCompany c,
    ValueChanged<String?> pick,
  ) {
    final selected = selectedId == c.id;
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.md),
      onTap: () => pick(selected ? null : c.id),
      child: SizedBox(
        width: 92,
        child: Column(
          children: [
            Container(
              width: 92,
              height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
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
                            : c.name.trim().characters.first.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                        ),
                      ),
                    )
                  : NetworkImageWithFallback(
                      url: c.logoUrl,
                      fallbackIcon: Icons.storefront_outlined,
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              c.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMuted.copyWith(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.ink900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
