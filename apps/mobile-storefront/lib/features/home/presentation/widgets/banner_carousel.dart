import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/placeholder_image.dart';
import '../../domain/home_banner.dart';

/// Promo carousel fed by the admin-managed `banners` collection, inset from
/// the screen edges with rounded corners. Image-only slides are shown as-is; slides with a
/// headline get a dark-green gradient and the headline in the app language.
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key, required this.banners});

  final List<HomeBanner> banners;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    if (widget.banners.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!_controller.hasClients) return;
        _controller.animateToPage(
          (_page + 1) % widget.banners.length,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    final lang = Localizations.localeOf(context).languageCode;
    return Column(
      children: [
        SizedBox(
          height: 184,
          width: double.infinity,
          child: PageView.builder(
            controller: _controller,
            itemCount: banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final banner = banners[i];
              final title = banner.titleFor(lang);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NetworkImageWithFallback(
                        url: banner.imageUrl,
                        fallbackIcon: Icons.solar_power_outlined,
                        cacheWidth: 900,
                      ),
                      if (banner.overlay != null)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                banner.overlay!.withValues(alpha: 0.9),
                                banner.overlay!.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.7],
                            ),
                          ),
                        ),
                      if (title != null && title.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          child: Align(
                            alignment: AlignmentDirectional.bottomStart,
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.sectionTitle.copyWith(
                                color: Colors.white,
                                height: 1.25,
                                fontSize: 19,
                                // Keeps the headline legible when no shade is chosen.
                                shadows: const [
                                  Shadow(color: Colors.black54, blurRadius: 8),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (banners.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.line,
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
