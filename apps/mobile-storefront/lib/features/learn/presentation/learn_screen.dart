import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/learn_article.dart';
import 'article_screen.dart';
import 'article_text.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSunken,
        elevation: 0,
        title: Text(AppLocalizations.of(context).learnTitle, style: AppTypography.h1.copyWith(fontSize: 20)),
        centerTitle: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: learnArticles.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) {
          final l10n = AppLocalizations.of(context);
          final article = learnArticles[i];
          final text = articleTextFor(article.id, l10n);
          return Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.card),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ArticleScreen(article: article)),
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  children: [
                    Icon(article.icon, size: 22, color: AppColors.ink900),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(text.title, style: AppTypography.cardTitle),
                          const SizedBox(height: 2),
                          Text(l10n.minRead(article.minutes), style: AppTypography.bodyMuted),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.ink400),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
