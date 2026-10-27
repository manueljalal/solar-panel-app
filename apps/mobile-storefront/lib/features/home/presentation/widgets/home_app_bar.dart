import 'package:flutter/material.dart';
import '../../../../core/city/city_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/city_picker.dart';

/// The "Solary" title and the shopper's city (tap to change) at the top of
/// the home screen (not a real AppBar — this scrolls away with the rest of
/// the sliver list). The city is the same one as Account → Location.
///
/// "Solary" itself is a brand name and stays in Latin script in every
/// language — everything else here is translated.
class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final cities = CityController.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Solary', style: AppTypography.h1),
        const SizedBox(height: 2),
        ValueListenableBuilder<String?>(
          valueListenable: cities,
          builder: (context, _, _) => InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () async {
              final picked = await showIraqCityPicker(context, selectedId: cities.value);
              if (picked != null && picked.isNotEmpty) await cities.set(picked);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.ink600),
                const SizedBox(width: 3),
                Text(cities.city?.nameFor(lang) ?? l10n.cityChoose, style: AppTypography.bodyMuted),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.ink600),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
