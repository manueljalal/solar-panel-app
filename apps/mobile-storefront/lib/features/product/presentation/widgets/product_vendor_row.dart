import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/rating.dart';
import '../../../home/data/home_repository.dart';
import '../../../home/presentation/company_store_screen.dart';

/// The "sold by X · ★ rating" line under the product title — tapping it
/// opens that company's store page.
class ProductVendorRow extends StatefulWidget {
  const ProductVendorRow({
    super.key,
    required this.vendorId,
    required this.vendor,
    required this.rating,
    required this.sold,
  });

  final String vendorId;
  final String vendor;
  final double rating;
  final int sold;

  @override
  State<ProductVendorRow> createState() => _ProductVendorRowState();
}

class _ProductVendorRowState extends State<ProductVendorRow> {
  bool _opening = false;

  Future<void> _openStore() async {
    if (_opening) return;
    setState(() => _opening = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      final company = await HomeRepository().fetchCompany(widget.vendorId);
      if (!mounted) return;
      if (company == null) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.homeLoadError)));
        return;
      }
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CompanyStoreScreen(company: company)));
    } catch (_) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text(l10n.homeLoadError)));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _openStore,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Flexible(child: Text(widget.vendor, overflow: TextOverflow.ellipsis, style: AppTypography.link)),
            const SizedBox(width: 4),
            _opening
                ? const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accent))
                : const Icon(Icons.chevron_right, size: 16, color: AppColors.accent),
            const Spacer(),
            const Icon(Icons.star, size: 14, color: AppColors.accent),
            const SizedBox(width: 3),
            Text(ratingLabel(context, widget.rating), style: AppTypography.bodyMuted.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            Text('(${widget.sold})', style: AppTypography.bodyMuted),
          ],
        ),
      ),
    );
  }
}
