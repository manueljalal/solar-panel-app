import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/learn_article.dart';
import 'article_text.dart';

class ArticleScreen extends StatelessWidget {
  const ArticleScreen({super.key, required this.article});

  final LearnArticle article;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = articleTextFor(article.id, l10n);
    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSunken,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(article.icon, size: 32, color: AppColors.ink900),
            const SizedBox(height: AppSpacing.md),
            Text(text.title, style: AppTypography.h1.copyWith(fontSize: 22)),
            const SizedBox(height: 4),
            Text(l10n.minRead(article.minutes), style: AppTypography.bodyMuted),
            const SizedBox(height: AppSpacing.lg),
            Text(text.body, style: AppTypography.body.copyWith(color: AppColors.ink600, height: 1.6)),
          ],
        ),
      ),
    );
  }
}
