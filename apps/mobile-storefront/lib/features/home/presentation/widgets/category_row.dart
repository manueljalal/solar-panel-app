import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/placeholder_image.dart';
import '../../domain/home_category.dart';

/// Horizontal category filter: an "All" chip followed by one image tile per
/// admin-managed category. [selectedId] null means All.
class CategoryRow extends StatelessWidget {
  const CategoryRow({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<HomeCategory> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) {
          if (i == 0) {
            return _Tile(
              label: l10n.categoryAll,
              selected: selectedId == null,
              onTap: () => onSelected(null),
              selectedFill: true,
              child: Center(
                child: Icon(
                  Icons.apps_rounded,
                  color: selectedId == null ? Colors.white : AppColors.ink600,
                ),
              ),
            );
          }
          final c = categories[i - 1];
          return _Tile(
            label: c.nameFor(lang),
            selected: selectedId == c.id,
            onTap: () => onSelected(selectedId == c.id ? null : c.id),
            child: NetworkImageWithFallback(
              url: c.imageUrl,
              fallbackIcon: Icons.category_outlined,
              cacheWidth: 200,
            ),
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
    this.selectedFill = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  /// Selected state fills the tile with the brand green (for icon tiles)
  /// instead of only outlining it (for photo tiles).
  final bool selectedFill;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.md),
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: selected && selectedFill
                    ? AppColors.primary
                    : AppColors.placeholderFill,
                borderRadius: BorderRadius.circular(AppSpacing.md),
                border: Border.all(
                  color: selected ? AppColors.primary : Colors.transparent,
                  width: 2.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMuted.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
