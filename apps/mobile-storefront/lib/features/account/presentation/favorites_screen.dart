import 'package:flutter/material.dart';
import '../../../core/favorites/favorites_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../../home/domain/home_product.dart';
import '../../home/presentation/widgets/product_tile.dart';

/// Products the shopper hearted, as the same grid as Home.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, HomeRepository? repository}) : _repository = repository;

  final HomeRepository? _repository;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late final HomeRepository _repo = widget._repository ?? HomeRepository();
  Future<List<HomeProduct>>? _products;

  @override
  void initState() {
    super.initState();
    FavoritesController.instance.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    FavoritesController.instance.removeListener(_load);
    super.dispose();
  }

  void _load() {
    final next = _repo.fetchProductsByIds(FavoritesController.instance.value.toList());
    setState(() {
      _products = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tileWidth = (MediaQuery.of(context).size.width - AppSpacing.lg * 2 - AppSpacing.md) / 2;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.accountFavorites, style: AppTypography.h1.copyWith(fontSize: 18)),
      ),
      body: FutureBuilder<List<HomeProduct>>(
        future: _products,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: TextButton(onPressed: _load, child: Text(l10n.retry)),
            );
          }
          final products = snap.data ?? const [];
          if (products.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border, size: 40, color: AppColors.primary.withValues(alpha: 0.5)),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.favoritesEmpty, textAlign: TextAlign.center, style: AppTypography.bodyMuted),
                  ],
                ),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.lg,
              crossAxisSpacing: AppSpacing.md,
              mainAxisExtent: ProductTile.extentFor(tileWidth),
            ),
            itemCount: products.length,
            itemBuilder: (_, i) => ProductTile(product: products[i]),
          );
        },
      ),
    );
  }
}
