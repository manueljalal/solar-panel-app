import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/placeholder_image.dart';
import '../../../search/presentation/search_screen.dart';
import '../../../wattage_calculator/presentation/wattage_calculator_screen.dart';
import '../../domain/home_banner.dart';

class _BannerText {
  const _BannerText({required this.eyebrow, required this.headline, required this.cta});
  final String eyebrow;
  final String headline;
  final String cta;
}

_BannerText _textFor(HomeBannerCopy copy, AppLocalizations l10n) {
  switch (copy) {
    case HomeBannerCopy.zeroDown:
      return _BannerText(
        eyebrow: l10n.bannerLimitedOffer,
        headline: l10n.bannerZeroDownTitle,
        cta: l10n.bannerGetQuote,
      );
    case HomeBannerCopy.batteryStorage:
      return _BannerText(
        eyebrow: l10n.bannerNewLabel,
        headline: l10n.bannerBatteryTitle,
        cta: l10n.bannerExploreBatteries,
      );
    case HomeBannerCopy.vettedVendors:
      return _BannerText(
        eyebrow: l10n.bannerVettedNetwork,
        headline: l10n.bannerVendorsTitle,
        cta: l10n.bannerMeetVendors,
      );
  }
}

/// Full-bleed, edge-to-edge promo carousel — no card margin, no rounded
/// corners butting against the page background. This is the one place the
/// layout should feel like it interrupts the page rather than floating
/// on it.
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 210,
          width: double.infinity,
          child: PageView.builder(
            controller: _controller,
            itemCount: homeBanners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => _BannerSlide(banner: homeBanners[i]),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(homeBanners.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppColors.ink : AppColors.line,
                borderRadius: BorderRadius.circular(AppRadii.chip),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BannerSlide extends StatelessWidget {
  const _BannerSlide({required this.banner});

  final HomeBanner banner;

  void _onCtaTap(BuildContext context) {
    // "Get a quote" leads to the wattage calculator (the natural first
    // step toward a quote); the other banners lead to search/browse,
    // matching their content (batteries, vendors) better than a dead tap.
    if (banner.copy == HomeBannerCopy.zeroDown) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WattageCalculatorScreen()));
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _textFor(banner.copy, AppLocalizations.of(context));
    return Stack(
      fit: StackFit.expand,
      children: [
        NetworkImageWithFallback(url: banner.imageUrl, fallbackIcon: Icons.solar_power_outlined),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.ink.withValues(alpha: 0.92),
                AppColors.ink.withValues(alpha: 0.78),
                AppColors.ink.withValues(alpha: 0.15),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
                child: Text(text.eyebrow, style: AppTypography.eyebrow),
              ),
              const SizedBox(height: 10),
              Text(
                text.headline,
                style: AppTypography.sectionTitle.copyWith(
                  color: Colors.white,
                  height: 1.25,
                  fontSize: 21,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _onCtaTap(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadii.chip),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(text.cta, style: AppTypography.link.copyWith(color: AppColors.ink)),
                      const Icon(Icons.chevron_right, color: AppColors.ink, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
