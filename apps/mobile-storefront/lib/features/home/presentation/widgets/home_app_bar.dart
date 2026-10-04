import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

/// The "Solary" title, location dropdown, and notification bell shown at
/// the top of the home screen (not a real AppBar — this scrolls away with
/// the rest of the sliver list).
///
/// "Solary" itself is a brand name and stays in Latin script in every
/// language (a deliberate choice, not an oversight — see
/// lib/l10n/app_en.arb's history) — everything else here is translated.
class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Solary', style: AppTypography.h1),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.ink600),
                const SizedBox(width: 3),
                Text(l10n.locationErbilIraq, style: AppTypography.bodyMuted),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.ink600),
              ],
            ),
          ],
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none, size: 26, color: AppColors.ink900),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
