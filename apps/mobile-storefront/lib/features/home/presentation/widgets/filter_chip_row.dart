import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/home_product.dart';

enum ProductSort { bestSelling, topRated, priceLow, priceHigh }

/// Rough IQD per USD, used only to put USD and IQD prices in one order —
/// never shown to anyone.
const _iqdPerUsd = 1310.0;

double _priceInIqd(HomeProduct p) => p.currency == 'USD' ? p.priceValue * _iqdPerUsd : p.priceValue;

/// [products] in the order [sort] asks for (a new list; ties keep the
/// best-selling order).
List<HomeProduct> sortProducts(List<HomeProduct> products, ProductSort sort) {
  int primary(HomeProduct a, HomeProduct b) => switch (sort) {
        ProductSort.bestSelling => 0,
        ProductSort.topRated => b.rating.compareTo(a.rating),
        ProductSort.priceLow => _priceInIqd(a).compareTo(_priceInIqd(b)),
        ProductSort.priceHigh => _priceInIqd(b).compareTo(_priceInIqd(a)),
      };
  return [...products]..sort((a, b) {
      final c = primary(a, b);
      return c != 0 ? c : b.sold.compareTo(a.sold);
    });
}

String sortLabel(AppLocalizations l10n, ProductSort sort) => switch (sort) {
      ProductSort.bestSelling => l10n.sortBestSelling,
      ProductSort.topRated => l10n.sortTopRated,
      ProductSort.priceLow => l10n.sortPriceLow,
      ProductSort.priceHigh => l10n.sortPriceHigh,
    };

/// The sort control next to the product section title: shows the current
/// order and opens a sheet to change it.
class SortButton extends StatelessWidget {
  const SortButton({super.key, required this.value, required this.onChanged});

  final ProductSort value;
  final ValueChanged<ProductSort> onChanged;

  Future<void> _open(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<ProductSort>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
              child: Text(l10n.sortBy, style: AppTypography.sectionTitle),
            ),
            for (final option in ProductSort.values)
              ListTile(
                title: Text(
                  sortLabel(l10n, option),
                  style: AppTypography.body.copyWith(
                    fontWeight: option == value ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                trailing: option == value ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (picked != null && picked != value) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.surface,
      shape: const StadiumBorder(side: BorderSide(color: AppColors.line)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.swap_vert, size: 16, color: AppColors.ink900),
              const SizedBox(width: 4),
              Text(
                sortLabel(l10n, value),
                style: AppTypography.body.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.ink600),
            ],
          ),
        ),
      ),
    );
  }
}
