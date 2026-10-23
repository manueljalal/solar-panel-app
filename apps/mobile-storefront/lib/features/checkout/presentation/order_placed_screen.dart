import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../orders/domain/order.dart';

/// Shown once after a successful checkout. Pops with true when the shopper
/// taps "View my orders" so the caller (CartScreen) can switch tabs.
class OrderPlacedScreen extends StatelessWidget {
  const OrderPlacedScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shortId = CustomerOrder.shortIdOf(orderId);
    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: AppBar(backgroundColor: AppColors.surfaceSunken, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.check_circle_outline, size: 56, color: AppColors.success),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.orderPlacedTitle, style: AppTypography.h1, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.orderNumber(shortId), style: AppTypography.bodyMuted, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.orderPlacedBody, style: AppTypography.body, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.chip)),
                ),
                child: Text(l10n.orderPlacedViewOrders, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
