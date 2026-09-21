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
  });

  final String url;
  final IconData fallbackIcon;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _Placeholder(icon: fallbackIcon, loading: true);
      },
      errorBuilder: (context, error, stackTrace) => _Placeholder(icon: fallbackIcon),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, this.loading = false});

  final IconData icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.placeholderFill),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.placeholderIcon),
              )
            : Icon(icon, color: AppColors.placeholderIcon, size: 30),
      ),
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
      child: Center(
        child: Icon(icon, color: iconColor, size: 34),
      ),
    );
  }
}
