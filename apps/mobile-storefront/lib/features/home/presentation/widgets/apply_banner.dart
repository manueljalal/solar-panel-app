import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/placeholder_image.dart';
import '../../../vendor/presentation/vendor_apply_screen.dart';

/// Vendor onboarding lives here — a card, not a separate app. A real photo
/// carries the tile; the ask sits directly on the image, not beside a
/// generic glyph. Tapping it opens the real application form.
class ApplyBanner extends StatelessWidget {
  const ApplyBanner({super.key});

  static const _imageUrl = 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=600&q=80';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const VendorApplyScreen()),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            boxShadow: AppShadows.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.card),
            child: Stack(
              fit: StackFit.expand,
              children: [
                NetworkImageWithFallback(url: _imageUrl, fallbackIcon: Icons.storefront_outlined),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.2, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.applyBannerTitle,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5, height: 1.1),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadii.chip),
                        ),
                        child: Text(
                          l10n.apply,
                          style: const TextStyle(color: AppColors.ink900, fontWeight: FontWeight.w700, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
