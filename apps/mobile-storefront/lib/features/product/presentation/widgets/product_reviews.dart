import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/reviews_repository.dart';

/// "Reviews" section on the product page. Renders nothing for products
/// without an id (test fixtures) or before Firebase is up.
class ProductReviews extends StatefulWidget {
  const ProductReviews({super.key, required this.productId, required this.reviewCount});

  final String productId;
  final int reviewCount;

  @override
  State<ProductReviews> createState() => _ProductReviewsState();
}

class _ProductReviewsState extends State<ProductReviews> {
  Future<List<ProductReview>>? _future;

  @override
  void initState() {
    super.initState();
    if (widget.productId.isNotEmpty && widget.reviewCount > 0 && Firebase.apps.isNotEmpty) {
      _future = ReviewsRepository().latestFor(widget.productId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<ProductReview>>(
      future: future,
      builder: (context, snap) {
        final reviews = snap.data;
        if (reviews == null || reviews.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.reviewsTitle(widget.reviewCount), style: AppTypography.sectionTitle.copyWith(fontSize: 16)),
            const SizedBox(height: AppSpacing.sm),
            for (final r in reviews)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        for (var i = 1; i <= 5; i++)
                          Icon(i <= r.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 16, color: AppColors.accent),
                        const SizedBox(width: AppSpacing.sm),
                        Text(r.reviewerName.isEmpty ? l10n.reviewVerifiedBuyer : r.reviewerName,
                            style: AppTypography.bodyMuted),
                      ],
                    ),
                    if (r.comment.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(r.comment, style: AppTypography.body.copyWith(color: AppColors.ink600)),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
