import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/order.dart';

String orderStatusLabel(AppLocalizations l10n, OrderStatus status) => switch (status) {
      OrderStatus.placed => l10n.orderStatusPlaced,
      OrderStatus.confirmed => l10n.orderStatusConfirmed,
      OrderStatus.installationScheduled => l10n.orderStatusScheduled,
      OrderStatus.installerEnRoute => l10n.orderStatusEnRoute,
      OrderStatus.installedVerified => l10n.orderStatusInstalled,
      OrderStatus.cancelled => l10n.orderStatusCancelled,
    };

/// "15 Oct 2026". Falls back to English month names for a locale intl has
/// no date symbols for (ckb), rather than throwing.
String formatOrderDate(DateTime date, String localeTag) {
  try {
    return DateFormat.yMMMd(localeTag).format(date);
  } catch (_) {
    return DateFormat.yMMMd('en').format(date);
  }
}

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      OrderStatus.cancelled => (AppColors.surfaceMuted, AppColors.ink600),
      OrderStatus.installedVerified => (AppColors.primarySoft, AppColors.success),
      _ => (const Color(0xFFF6EBDD), AppColors.warning),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadii.chip)),
      child: Text(
        orderStatusLabel(AppLocalizations.of(context), status),
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
