import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/placeholder_image.dart';
import '../../home/presentation/widgets/banner_carousel.dart';
import '../data/learn_repository.dart';
import '../domain/course.dart';
import '../domain/learn_item.dart';
import 'course_screen.dart';
import 'learn_item_screen.dart';
import 'learn_poster.dart';

/// Learn tab: admin-managed banners on top, then courses (series of
/// episodes, free or Premium) and standalone quick videos.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key, LearnRepository? repository}) : _repository = repository;

  final LearnRepository? _repository;

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  late final LearnRepository _repository = widget._repository ?? LearnRepository();
  late Future<LearnContent> _content = _repository.fetchAll();

  Future<void> _reload() async {
    final next = _repository.fetchAll();
    setState(() {
      _content = next;
    });
    await next.then<void>((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.learnTitle, style: AppTypography.h1.copyWith(fontSize: 20)),
        centerTitle: false,
      ),
      body: FutureBuilder<LearnContent>(
        future: _content,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(child: Text(l10n.homeLoadError, style: AppTypography.bodyMuted)),
                  TextButton(onPressed: _reload, child: Text(l10n.retry)),
                ],
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final content = snapshot.data!;
          if (content.isEmpty) {
            return Center(child: Text(l10n.learnEmpty, style: AppTypography.bodyMuted));
          }
          const side = EdgeInsets.symmetric(horizontal: AppSpacing.lg);
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: [
                Padding(padding: side, child: Text(l10n.learnTeaserSubtitle, style: AppTypography.bodyMuted)),
                if (content.banners.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  BannerCarousel(
                    key: ValueKey(content.banners.map((b) => b.id).join(',')),
                    banners: content.banners,
                  ),
                ],
                if (content.courses.isNotEmpty) ...[
                  _SectionTitle(l10n.learnCourses),
                  for (final c in content.courses)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                      child: _CourseCard(course: c),
                    ),
                ],
                if (content.standalone.isNotEmpty) ...[
                  _SectionTitle(l10n.learnQuickVideos),
                  for (final item in content.standalone)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                      child: _VideoCard(item: item),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
        child: Text(text, style: AppTypography.sectionTitle),
      );
}

/// Free / Premium pill used on course cards and the course page.
class CourseAccessBadge extends StatelessWidget {
  const CourseAccessBadge({super.key, required this.course, this.onImage = false});

  final Course course;
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paid = course.isPaid;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: onImage ? Colors.white : (paid ? AppColors.accent.withValues(alpha: 0.14) : AppColors.primarySoft),
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(paid ? Icons.workspace_premium_outlined : Icons.lock_open_outlined, size: 13, color: paid ? AppColors.accent : AppColors.primary),
          const SizedBox(width: 4),
          Text(
            paid ? (course.priceLabel.isNotEmpty ? '${l10n.learnPremium} · ${course.priceLabel}' : l10n.learnPremium) : l10n.learnFree,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: paid ? AppColors.accent : AppColors.primary),
          ),
        ],
      ),
    );
  }
}

/// Course cover: its own image, or the first episode's video frame.
class CourseCover extends StatelessWidget {
  const CourseCover({super.key, required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    if (course.coverUrl.isNotEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: NetworkImageWithFallback(url: course.coverUrl, fallbackIcon: Icons.school_outlined, cacheWidth: 900),
      );
    }
    return LearnPoster(item: course.episodes.first, showPlay: false);
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final minutes = (course.totalSeconds / 60).round();
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CourseScreen(course: course))),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CourseCover(course: course),
                PositionedDirectional(top: 10, start: 10, child: CourseAccessBadge(course: course, onImage: true)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.titleFor(lang),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cardTitle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.playlist_play, size: 18, color: AppColors.ink600),
                      const SizedBox(width: 4),
                      Text(l10n.learnEpisodes(course.episodes.length), style: AppTypography.bodyMuted),
                      if (minutes > 0) ...[
                        Text('  ·  ', style: AppTypography.bodyMuted),
                        Text(l10n.learnMinutes(minutes), style: AppTypography.bodyMuted),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.item});

  final LearnItem item;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LearnItemScreen(item: item))),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LearnPoster(item: item),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.titleFor(lang), maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.cardTitle.copyWith(fontSize: 16)),
                  if (item.descriptionFor(lang).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(item.descriptionFor(lang), maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.bodyMuted),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
