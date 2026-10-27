import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../iraq_cities.dart';

/// Bottom sheet listing Iraq's cities in the app language. Returns the
/// chosen city id, '' for "All cities" (only when [allowAll]), or null if
/// dismissed. [counts] (city id -> number) shows how many results each city
/// has; cities with results are listed first.
Future<String?> showIraqCityPicker(
  BuildContext context, {
  String? selectedId,
  Map<String, int> counts = const {},
  bool allowAll = false,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card))),
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx);
      final lang = Localizations.localeOf(ctx).languageCode;
      final cities = [...iraqCities]..sort((a, b) {
          final byCount = (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0);
          return byCount != 0 ? byCount : a.nameFor(lang).compareTo(b.nameFor(lang));
        });
      Widget tile(String id, String label, int? count) {
        final selected = (selectedId ?? '') == id;
        return ListTile(
          title: Text(label, style: AppTypography.body.copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (count != null && count > 0) Text('$count', style: AppTypography.bodyMuted),
              if (selected) ...[
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.check, color: AppColors.primary, size: 20),
              ],
            ],
          ),
          onTap: () => Navigator.of(ctx).pop(id),
        );
      }

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                child: Text(l10n.cityPickerTitle, style: AppTypography.sectionTitle.copyWith(fontSize: 17)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (allowAll) tile('', l10n.cityAll, counts.values.fold<int>(0, (a, b) => a + b)),
                    for (final c in cities) tile(c.id, c.nameFor(lang), counts[c.id]),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Compact "📍 City ▾" pill that opens the picker.
class CityFilterChip extends StatelessWidget {
  const CityFilterChip({super.key, required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.ink600;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.chip),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.chip),
          border: Border.all(color: active ? AppColors.primary : AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_outlined, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
            Icon(Icons.keyboard_arrow_down, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}
