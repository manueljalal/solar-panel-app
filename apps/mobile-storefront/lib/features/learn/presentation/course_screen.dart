import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/course.dart';
import '../domain/learn_item.dart';
import 'learn_item_screen.dart';
import 'learn_screen.dart';

/// One course: cover, title, Free/Premium, description and the numbered
/// episode list. In a Premium course only episode 1 plays (free preview);
/// the others show a lock and a "coming soon" sheet.
class CourseScreen extends StatelessWidget {
  const CourseScreen({super.key, required this.course});

  final Course course;

  void _open(BuildContext context, LearnItem episode) {
    if (course.canWatch(episode)) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => LearnItemScreen(item: episode)));
      return;
    }
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium_outlined, size: 44, color: AppColors.accent),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.learnLockedTitle, style: AppTypography.h1.copyWith(fontSize: 20)),
              if (course.priceLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(course.priceLabel, style: AppTypography.cardTitle.copyWith(color: AppColors.accent)),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.learnLockedBody, textAlign: TextAlign.center, style: AppTypography.bodyMuted),
              const SizedBox(height: AppSpacing.lg),
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.done)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final minutes = (course.totalSeconds / 60).round();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(backgroundColor: AppColors.surface, elevation: 0, scrolledUnderElevation: 0),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          CourseCover(course: course),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CourseAccessBadge(course: course),
                const SizedBox(height: AppSpacing.sm),
                Text(course.titleFor(lang), style: AppTypography.h1.copyWith(fontSize: 22)),
                const SizedBox(height: 4),
                Text(
                  [l10n.learnEpisodes(course.episodes.length), if (minutes > 0) l10n.learnMinutes(minutes)].join('  ·  '),
                  style: AppTypography.bodyMuted,
                ),
                if (course.descriptionFor(lang).isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(course.descriptionFor(lang), style: AppTypography.body.copyWith(height: 1.45)),
                ],
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _open(context, course.episodes.first),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(course.isPaid ? l10n.learnFreePreview : l10n.learnStartCourse,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.chip)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.line),
          for (var i = 0; i < course.episodes.length; i++)
            _EpisodeRow(
              number: i + 1,
              episode: course.episodes[i],
              locked: !course.canWatch(course.episodes[i]),
              preview: course.isPaid && i == 0,
              onTap: () => _open(context, course.episodes[i]),
            ),
        ],
      ),
    );
  }
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({
    required this.number,
    required this.episode,
    required this.locked,
    required this.preview,
    required this.onTap,
  });

  final int number;
  final LearnItem episode;
  final bool locked;
  final bool preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: locked ? AppColors.surfaceSunken : AppColors.primarySoft,
              ),
              child: Text(
                '$number',
                style: TextStyle(fontWeight: FontWeight.w800, color: locked ? AppColors.ink400 : AppColors.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode.titleFor(lang),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cardTitle.copyWith(color: locked ? AppColors.ink600 : AppColors.ink900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (episode.durationLabel != null) episode.durationLabel!,
                      if (preview) l10n.learnFreePreview,
                    ].join('  ·  '),
                    style: AppTypography.bodyMuted.copyWith(fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Icon(
              locked ? Icons.lock_outline : Icons.play_circle_outline,
              color: locked ? AppColors.ink400 : AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
