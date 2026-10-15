import 'package:flutter/material.dart';
import '../../../../core/auth/auth_claims.dart';
import '../../../../core/auth/auth_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/placeholder_image.dart';
import '../../../bulk/presentation/bulk_market_screen.dart';
import '../../../vendor/presentation/vendor_apply_screen.dart';

/// Vendor onboarding lives here — a card, not a separate app. A real photo
/// carries the tile; the ask sits directly on the image, not beside a
/// generic glyph. Tapping it opens the real application form.
///
/// B2B is a first-class path, so on Home this is the large anchor tile
/// (`large: true`: bigger title, a one-line pitch, a full CTA button).
///
/// For an approved vendor the same tile becomes the entry to the bulk
/// marketplace (wholesale prices + bulk requests) instead of the apply form.
class ApplyBanner extends StatefulWidget {
  const ApplyBanner({super.key, this.large = false});

  final bool large;

  @override
  State<ApplyBanner> createState() => _ApplyBannerState();
}

class _ApplyBannerState extends State<ApplyBanner> {
  bool _isVendor = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  /// Role is a nicety for the tile's wording and destination — if claims
  /// can't be read the tile simply stays the apply card.
  Future<void> _loadRole() async {
    try {
      // forceRefresh: the vendor role is granted server-side AFTER sign-in, so
      // the cached token is stale right after approval.
      final claims = await AuthRepository().getClaims(forceRefresh: true);
      if (mounted && claims.role == AppRole.vendor)
        setState(() => _isVendor = true);
    } catch (_) {}
  }

  bool get large => widget.large;

  static const _imageUrl =
      'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=600&q=80';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _isVendor
                ? const BulkMarketScreen()
                : const VendorApplyScreen(),
          ),
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
                NetworkImageWithFallback(
                  url: _imageUrl,
                  fallbackIcon: Icons.storefront_outlined,
                ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isVendor ? l10n.homeBulkTitle : l10n.applyBannerTitle,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: large ? 20 : 12.5,
                          height: 1.1,
                        ),
                      ),
                      if (large) ...[
                        const SizedBox(height: 4),
                        Text(
                          _isVendor
                              ? l10n.homeBulkSubtitle
                              : l10n.applyBannerSubtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                            height: 1.25,
                          ),
                        ),
                      ],
                      SizedBox(height: large ? 10 : 5),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: large ? 14 : 9,
                          vertical: large ? 7 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadii.chip),
                        ),
                        child: Text(
                          _isVendor ? l10n.homeBulkCta : l10n.apply,
                          style: TextStyle(
                            color: AppColors.ink900,
                            fontWeight: FontWeight.w700,
                            fontSize: large ? 12.5 : 11,
                          ),
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
