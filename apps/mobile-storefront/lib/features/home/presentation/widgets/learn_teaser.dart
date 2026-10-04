import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

/// A small tile pulling in a Learn article preview instead of leaving
/// "Learn" as a separate, disconnected section on the home screen.
class LearnTeaser extends StatelessWidget {
  const LearnTeaser({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.menu_book_outlined, size: 18, color: AppColors.ink900),
          Text(
            l10n.learnTeaserTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.cardTitle.copyWith(fontSize: 11.5, height: 1.15),
          ),
          Text(l10n.learnTeaserReadTime, style: AppTypography.bodyMuted.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
