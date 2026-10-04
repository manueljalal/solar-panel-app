import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../data/vendor_product_repository.dart';
import 'vendor_product_form_screen.dart';
import 'widgets/vendor_product_list_tile.dart';

/// The real vendor dashboard — lists this vendor's own products (live
/// Firestore stream, scoped by vendorId) with add/edit/delete. Reached
/// only for accounts holding the 'vendor' role claim (see
/// core/navigation/root_shell.dart's role gate).
class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key, required this.vendorId, VendorProductRepository? repository})
      : _repository = repository;

  final String vendorId;
  final VendorProductRepository? _repository;

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  late final _repository = widget._repository ?? VendorProductRepository();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSunken,
        elevation: 0,
        title: Text(l10n.myProductsTitle, style: AppTypography.h1.copyWith(fontSize: 19)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VendorProductFormScreen(vendorId: widget.vendorId, repository: _repository),
          ),
        ),
        backgroundColor: AppColors.ink,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(l10n.addProduct, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<List<VendorOwnedProduct>>(
        stream: _repository.watchOwnProducts(widget.vendorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(l10n.couldntLoadProducts, style: AppTypography.bodyMuted),
            );
          }

          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.ink400),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.noProductsYetTitle, style: AppTypography.cardTitle),
                    const SizedBox(height: 4),
                    Text(
                      l10n.noProductsYetBody,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMuted,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              final owned = items[i];
              return VendorProductListTile(
                owned: owned,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VendorProductFormScreen(
                      vendorId: widget.vendorId,
                      repository: _repository,
                      editing: owned,
                    ),
                  ),
                ),
                onDelete: () => _confirmDelete(context, owned),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, VendorOwnedProduct owned) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeProductTitle),
        content: Text(owned.product.title),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.remove, style: const TextStyle(color: AppColors.warning)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.delete(owned.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldntRemoveProduct)),
      );
    }
  }
}
