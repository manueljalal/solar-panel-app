import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Loads a real photo from [url] (stock imagery today, real vendor/product
/// uploads later) with a graceful icon fallback if the network request
/// fails or is still in flight — never a blank/broken box.
class NetworkImageWithFallback extends StatelessWidget {
  const NetworkImageWithFallback({
    super.key,
    required this.url,
    this.fallbackIcon = Icons.image_outlined,
    this.fit = BoxFit.cover,
    this.cacheWidth = 400,
  });

  final String url;
  final IconData fallbackIcon;
  final BoxFit fit;

  /// Decode the bitmap at (at most) this pixel width instead of full size —
  /// a 1600px upload shown in a 92px thumbnail otherwise holds the full
  /// decoded image in memory.
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _Placeholder(icon: fallbackIcon);
    // Cached on disk (not just in memory) so a cold start doesn't re-download
    // every image, and decoded at display size to keep memory low.
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      memCacheWidth: cacheWidth,
      fadeInDuration: const Duration(milliseconds: 120),
      placeholder: (context, _) =>
          _Placeholder(icon: fallbackIcon, loading: true),
      errorWidget: (context, _, _) => _Placeholder(icon: fallbackIcon),
    );
  }
}

/// Shown while an image loads and if it fails: a plain white tile with a
/// faint brand-tinted icon. No spinner (one per tile is noise, and it never
/// stops animating if a download stalls) and no grey box.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, this.loading = false});

  final IconData icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: loading
          ? const SizedBox.expand()
          : Center(child: Icon(icon, color: AppColors.primary.withValues(alpha: 0.3), size: 28)),
    );
  }
}

/// Simple flat-icon tile — kept for spots that intentionally show an icon
/// rather than a photo (e.g. the Learn article cards).
class PlaceholderImage extends StatelessWidget {
  const PlaceholderImage({
    super.key,
    this.icon = Icons.image_outlined,
    this.tint = AppColors.placeholderFill,
    this.iconColor = AppColors.ink900,
    this.borderRadius,
  });

  final IconData icon;
  final Color tint;
  final Color iconColor;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint,
        borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.md),
      ),
      child: Center(child: Icon(icon, color: iconColor, size: 34)),
    );
  }
}
