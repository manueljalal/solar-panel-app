import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/placeholder_image.dart';
import '../domain/learn_item.dart';

/// 16:9 cover for a Learn item: the video's thumbnail (or a brand-green
/// fallback), a soft bottom shade, a centred play button and the length pill.
class LearnPoster extends StatelessWidget {
  const LearnPoster({super.key, required this.item, this.showPlay = true});

  final LearnItem item;
  final bool showPlay;

  @override
  Widget build(BuildContext context) {
    final thumb = item.thumbnailUrl;
    final duration = item.durationLabel;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (thumb != null && thumb.isNotEmpty)
            NetworkImageWithFallback(url: thumb, fallbackIcon: Icons.play_circle_outline, cacheWidth: 800)
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.ink],
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent],
              ),
            ),
          ),
          if (showPlay)
            Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12)],
                ),
                child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 34),
              ),
            ),
          if (duration != null)
            Positioned(
              right: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
                child: Text(
                  duration,
                  style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
