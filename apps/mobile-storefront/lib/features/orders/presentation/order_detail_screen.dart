import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../../core/auth/friendly_function_error.dart';
import '../../../core/auth/phone_number.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/formatting/money.dart';
import '../../../shared/widgets/placeholder_image.dart';
import '../data/order_repository.dart';
import '../domain/order.dart';
import 'orders_screen.dart' show formatOrderDate;
import 'widgets/order_status_chip.dart';

/// One order: its lines, totals, delivery details, and — while the seller
/// hasn't confirmed it yet — a "Cancel order" button. The Orders list is a
/// live query, so a cancel shows up there without any manual refresh.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.order, required this.repository});

  final CustomerOrder order;
  final OrderRepository repository;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late OrderStatus _status = widget.order.status;
  bool _cancelling = false;

  Future<void> _cancel() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.orderCancelConfirmTitle),
        content: Text(l10n.orderCancelConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.orderKeep)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.orderCancel)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.repository.cancelOrder(widget.order.id);
      if (!mounted) return;
      setState(() {
        _status = OrderStatus.cancelled;
        _cancelling = false;
      });
      messenger.showSnackBar(SnackBar(content: Text(l10n.orderCancelled)));
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      messenger.showSnackBar(SnackBar(content: Text(friendlyFunctionError(e, l10n.orderCancelFailed))));
    } catch (_) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.orderCancelFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final order = widget.order;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSunken,
        elevation: 0,
        title: Text(l10n.orderDetailTitle, style: AppTypography.h1.copyWith(fontSize: 20)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              Expanded(child: Text(l10n.orderNumber(order.shortId), style: AppTypography.sectionTitle)),
              OrderStatusChip(status: _status),
            ],
          ),
          if (order.createdAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(formatOrderDate(order.createdAt!), style: AppTypography.bodyMuted),
          ],
          const SizedBox(height: AppSpacing.lg),
          _Card(
            title: l10n.orderItemsSection,
            children: [
              for (final line in order.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: NetworkImageWithFallback(url: line.imageUrl, fallbackIcon: Icons.solar_power_outlined),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(line.nameFor(languageCode), style: AppTypography.cardTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                            Text(
                              '${line.quantity} × ${formatMoney(line.unitPrice, line.currency)}',
                              style: AppTypography.bodyMuted,
                            ),
                          ],
                        ),
                      ),
                      Text(formatMoney(line.lineTotal, line.currency), style: AppTypography.body),
                    ],
                  ),
                ),
              const Divider(color: AppColors.line),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.checkoutTotal, style: AppTypography.cardTitle),
                  Flexible(child: Text(formatTotals(order.totals), style: AppTypography.price, textAlign: TextAlign.end)),
                ],
              ),
            ],
          ),
          _Card(
            title: l10n.orderDeliverTo,
            children: [
              Text(order.contactName, style: AppTypography.cardTitle),
              // Phone numbers stay left-to-right inside RTL text.
              Text(formatPhone(order.contactPhone), style: AppTypography.body, textDirection: TextDirection.ltr),
              const SizedBox(height: AppSpacing.xs),
              Text('${order.address}, ${order.city}', style: AppTypography.body),
              if (order.note.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(order.note, style: AppTypography.bodyMuted),
              ],
            ],
          ),
          _Card(
            title: l10n.checkoutPaymentSection,
            children: [Text(l10n.checkoutCashOnDelivery, style: AppTypography.body)],
          ),
          if (_status == OrderStatus.placed)
            OutlinedButton(
              onPressed: _cancelling ? null : _cancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: const BorderSide(color: AppColors.line),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.chip)),
              ),
              child: _cancelling
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.orderCancel, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}
