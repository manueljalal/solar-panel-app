import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

/// The small "Best match ▾" sort control next to the "Best sellers"
/// section title.
class FilterChipRow extends StatelessWidget {
  const FilterChipRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.sort, size: 16, color: AppColors.ink600),
        const SizedBox(width: 4),
        Text(l10n.bestMatch, style: AppTypography.bodyMuted.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
