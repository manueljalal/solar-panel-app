import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/learn_item.dart';
import 'learn_poster.dart';

/// A single Learn item: the video player on top, then the title and
/// description in the app's language. The video is only fetched here, when
/// the user opens the item.
class LearnItemScreen extends StatefulWidget {
  const LearnItemScreen({super.key, required this.item});

  final LearnItem item;

  @override
  State<LearnItemScreen> createState() => _LearnItemScreenState();
}

class _LearnItemScreenState extends State<LearnItemScreen> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.item.videoUrl));
    _controller.initialize().then((_) {
      if (mounted) setState(() => _ready = true);
    }).catchError((_) {
      if (mounted) setState(() => _failed = true);
    });
    _controller.addListener(() {
      // Rebuild for play/pause icon and the end-of-video state.
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      if (_controller.value.position >= _controller.value.duration) _controller.seekTo(Duration.zero);
      _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final item = widget.item;
    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: AppBar(backgroundColor: AppColors.surfaceSunken, elevation: 0, scrolledUnderElevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.card),
              child: AspectRatio(
                aspectRatio: _ready ? _controller.value.aspectRatio : 16 / 9,
                child: ColoredBox(
                  color: Colors.black,
                  child: _failed
                      ? Center(child: Text(l10n.learnVideoError, style: const TextStyle(color: Colors.white70)))
                      : !_ready
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                LearnPoster(item: item, showPlay: false),
                                const Center(child: CircularProgressIndicator(color: Colors.white)),
                              ],
                            )
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                VideoPlayer(_controller),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _togglePlay,
                                  child: AnimatedOpacity(
                                    opacity: _controller.value.isPlaying ? 0 : 1,
                                    duration: const Duration(milliseconds: 150),
                                    child: const Center(
                                      child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 64),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: VideoProgressIndicator(
                                    _controller,
                                    allowScrubbing: true,
                                    colors: const VideoProgressColors(
                                      playedColor: AppColors.primary,
                                      bufferedColor: Colors.white38,
                                      backgroundColor: Colors.white24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(item.titleFor(lang), style: AppTypography.h1.copyWith(fontSize: 23, height: 1.25)),
            if (item.durationLabel != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 15, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Text(item.durationLabel!, style: AppTypography.bodyMuted.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.card),
                boxShadow: AppShadows.card,
              ),
              child: Text(
                item.descriptionFor(lang),
                style: AppTypography.body.copyWith(color: AppColors.ink600, height: 1.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
