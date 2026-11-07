import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../../home/domain/home_product.dart';
import '../../home/presentation/widgets/product_row.dart';

/// Panel wattage from a product spec like "450W" / "585 w". Inverters
/// ("6kW") and batteries ("5kWh") don't match, which is what separates
/// panels from the rest of the catalogue.
int? panelWattageOf(HomeProduct p) {
  final m = RegExp(r'^\s*(\d{2,4})\s*w\s*$', caseSensitive: false).firstMatch(p.spec);
  return m == null ? null : int.parse(m.group(1)!);
}

/// The panels in [products], closest to [targetWattage] first.
List<HomeProduct> matchingPanels(List<HomeProduct> products, int targetWattage) {
  final panels = products.where((p) => panelWattageOf(p) != null).toList()
    ..sort((a, b) => (panelWattageOf(a)! - targetWattage).abs().compareTo((panelWattageOf(b)! - targetWattage).abs()));
  return panels;
}

/// Opened from the calculator's "See matching panels": the solar panels on
/// sale, ordered by how close their wattage is to the one the estimate used.
class MatchingPanelsScreen extends StatefulWidget {
  const MatchingPanelsScreen({super.key, required this.targetWattage, this.repository});

  final int targetWattage;
  final HomeRepository? repository;

  @override
  State<MatchingPanelsScreen> createState() => _MatchingPanelsScreenState();
}

class _MatchingPanelsScreenState extends State<MatchingPanelsScreen> {
  late final Future<List<HomeProduct>> _panels =
      (widget.repository ?? HomeRepository()).fetchProducts().then((all) => matchingPanels(all, widget.targetWattage));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSunken,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.calcPanels, style: AppTypography.h1.copyWith(fontSize: 19)),
      ),
      body: FutureBuilder<List<HomeProduct>>(
        future: _panels,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final panels = snap.data;
          final message = snap.hasError ? l10n.homeLoadError : (panels!.isEmpty ? l10n.calcNoPanels : null);
          if (message != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(message, textAlign: TextAlign.center, style: AppTypography.bodyMuted),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: panels!.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) => ProductRow(product: panels[i]),
          );
        },
      ),
    );
  }
}
