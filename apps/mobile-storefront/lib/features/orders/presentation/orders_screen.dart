import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

/// Orders tab. There's no checkout flow yet (see cart screen's "Checkout"
/// button), so there's genuinely nothing to list — this shows an honest
/// empty state rather than fake sample orders. Once checkout writes real
/// `orders/{orderId}` docs, this becomes a live query against that
/// collection, gated by the rules already in firestore.rules
/// (`allow read: if false` currently — will need an owner check once
/// orders exist).
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSunken,
        elevation: 0,
        title: Text(l10n.ordersTitle, style: AppTypography.h1.copyWith(fontSize: 20)),
        centerTitle: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.ink400),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.ordersEmptyTitle, style: AppTypography.cardTitle),
              const SizedBox(height: 4),
              Text(
                l10n.ordersEmptyBody,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
