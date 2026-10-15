import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../features/home/domain/home_category.dart';

/// Category filter as plain text tabs with an underline on the selected one
/// — shared by Home and the bulk marketplace so both headers stay light.
/// [selectedId] null means All.
class CategoryTabs extends StatelessWidget {
  const CategoryTabs({
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
    final items = <(String? id, String label)>[
      (null, l10n.categoryAll),
      for (final c in categories) (c.id, c.nameFor(lang)),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xl),
        itemBuilder: (context, i) {
          final (id, label) = items[i];
          final selected = selectedId == id;
          return InkWell(
            onTap: () => onSelected(selected && id != null ? null : id),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? AppColors.primary : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.ink600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
