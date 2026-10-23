import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/order.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, color) = switch (status) {
      OrderStatus.placed => (l10n.orderStatusPlaced, AppColors.ink600),
      OrderStatus.confirmed => (l10n.orderStatusConfirmed, AppColors.primary),
      OrderStatus.shipped => (l10n.orderStatusShipped, AppColors.accent),
      OrderStatus.delivered => (l10n.orderStatusDelivered, AppColors.success),
      OrderStatus.cancelled => (l10n.orderStatusCancelled, AppColors.ink400),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
