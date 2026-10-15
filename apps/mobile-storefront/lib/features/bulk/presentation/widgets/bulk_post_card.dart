import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/bulk_models.dart';
import 'country_flag.dart';

String formatQty(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

String formatUsd(double v) =>
    '\$${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2)}';

String countryLabel(AppLocalizations l10n, BulkCountry c) =>
    c == BulkCountry.china ? l10n.bulkCountryChina : l10n.bulkCountryIraq;

class CountryBadge extends StatelessWidget {
  const CountryBadge({super.key, required this.country, this.solid = false});

  final BulkCountry country;

  /// White pill, for sitting on top of a photo.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isChina = country == BulkCountry.china;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: solid
            ? Colors.white
            : (isChina
                  ? AppColors.accent.withValues(alpha: 0.14)
                  : AppColors.primarySoft),
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CountryFlag(country: country, width: 16),
          const SizedBox(width: 5),
          Text(
            countryLabel(l10n, country),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isChina ? AppColors.accent : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// One tile in the marketplace grid, kept deliberately plain: a square
/// photo with a hairline border, then title, price, and one muted line with
/// the flag and company. No card background, badges or captions.
/// [onClose] is only passed for the caller's own open posts.
class BulkPostCard extends StatelessWidget {
  const BulkPostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.onClose,
  });

  /// Height of everything under the square photo.
  static const _textBlock = 84.0;

  /// Grid row height for a tile of [tileWidth] (square photo + text).
  static double extentFor(double tileWidth) => tileWidth + _textBlock;

  final BulkPost post;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final p = post;
    final String price;
    final String detail;
    if (p is BulkListing) {
      price = '${formatUsd(p.bestPriceUsd)} / ${p.unit}';
      detail = l10n.bulkMinOrder(formatQty(p.moq), p.unit);
    } else {
      final r = p as BulkRequest;
      price = '${formatQty(r.quantity)} ${r.unit}';
      detail = r.targetPriceUsd != null
          ? l10n.bulkTargetPrice(formatUsd(r.targetPriceUsd!), r.unit)
          : '';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.card),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: _Photo(url: p.imageUrl, isRequest: p is BulkRequest),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            p.titleFor(lang),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.cardTitle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            price,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          if (detail.isNotEmpty)
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMuted.copyWith(fontSize: 12),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              CountryFlag(country: p.country, width: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  p.isMine ? l10n.bulkYours : p.businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMuted.copyWith(fontSize: 12),
                ),
              ),
              if (!p.isOpen)
                Text(
                  l10n.bulkClosed,
                  style: AppTypography.bodyMuted.copyWith(
                    fontSize: 12,
                    color: AppColors.warning,
                  ),
                )
              else if (onClose != null)
                InkWell(
                  onTap: onClose,
                  child: Text(
                    l10n.bulkClosePost,
                    style: AppTypography.link.copyWith(fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The post photo, or — with none — a plain white tile with a faint solar
/// glyph, so a missing photo still reads as a deliberate empty slot.
class _Photo extends StatelessWidget {
  const _Photo({required this.url, required this.isRequest});

  final String url;
  final bool isRequest;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Center(
      child: Icon(
        isRequest ? Icons.request_quote_outlined : Icons.solar_power_outlined,
        size: 38,
        color: AppColors.primary.withValues(alpha: 0.35),
      ),
    );
    if (url.isEmpty) return fallback();
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: 500,
      errorBuilder: (_, _, _) => fallback(),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : fallback(),
    );
  }
}

/// Full detail — tier table or request facts, plus contact actions for
/// someone else's post.
Future<void> showBulkPostSheet(BuildContext context, BulkPost post) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    builder: (_) => _BulkPostSheet(post: post),
  );
}

class _BulkPostSheet extends StatelessWidget {
  const _BulkPostSheet({required this.post});

  final BulkPost post;

  Future<void> _open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final p = post;
    final digits = p.phone.replaceAll(RegExp(r'\D'), '');
    final description = p.descriptionFor(lang);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CountryBadge(country: p.country),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(p.businessName, style: AppTypography.bodyMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (p.imageUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.card),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.network(
                    p.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              p.titleFor(lang),
              style: AppTypography.h1.copyWith(fontSize: 20),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(description, style: AppTypography.body),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (p is BulkListing) ...[
              Text(l10n.bulkPriceTiers, style: AppTypography.cardTitle),
              const SizedBox(height: AppSpacing.sm),
              for (final t in p.tiers)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.bulkTierRow(formatQty(t.minQty), p.unit),
                          style: AppTypography.body,
                        ),
                      ),
                      Text(
                        '${formatUsd(t.unitPriceUsd)} / ${p.unit}',
                        style: AppTypography.cardTitle.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ] else if (p is BulkRequest) ...[
              Text(
                l10n.bulkQuantityNeeded(formatQty(p.quantity), p.unit),
                style: AppTypography.cardTitle,
              ),
              if (p.targetPriceUsd != null)
                Text(
                  l10n.bulkTargetPrice(formatUsd(p.targetPriceUsd!), p.unit),
                  style: AppTypography.body,
                ),
              if (p.deliveryCity.isNotEmpty)
                Text(
                  l10n.bulkDeliverTo(p.deliveryCity),
                  style: AppTypography.body,
                ),
            ],
            if (!p.isMine && p.isOpen && digits.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _open(Uri(scheme: 'tel', path: '+$digits')),
                      icon: const Icon(Icons.call_outlined, size: 18),
                      label: Text(l10n.bulkCall),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _open(Uri.parse('https://wa.me/$digits')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: Text(l10n.bulkWhatsApp),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
