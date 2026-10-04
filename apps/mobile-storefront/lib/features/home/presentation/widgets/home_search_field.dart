import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/presentation/search_screen.dart';

/// The "Search panels, brands, packages" field at the top of the home
/// screen. Tapping it (this field is display-only, standard mobile
/// pattern) pushes the real SearchScreen, which does the actual typing +
/// live filtering.
class HomeSearchField extends StatelessWidget {
  const HomeSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.searchBar),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.searchBar),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        ),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.searchBar),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.ink600, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(l10n.searchHint, style: AppTypography.bodyMuted),
              ),
              const Icon(Icons.tune, color: AppColors.ink600, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
