import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../../core/auth/friendly_function_error.dart';
import '../../../core/auth/phone_number.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/placeholder_image.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../home/domain/home_product.dart';
import '../data/orders_repository.dart';
import '../domain/order.dart';
import 'order_status_label.dart';

/// One order: progress timeline, items, delivery details, and whatever the
/// customer can do at this stage — cancel (while placed), confirm the
/// installation (once the installer is on the way), review products (once
/// installed) or report a problem.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.order, required this.repository});

  final CustomerOrder order;
  final OrdersRepository repository;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late CustomerOrder _order = widget.order;
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      final fresh = await widget.repository.listMyOrders();
      if (!mounted) return;
      setState(() {
        _order = fresh.firstWhere((o) => o.id == _order.id, orElse: () => _order);
        _busy = false;
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = friendlyFunctionError(e, l10n.genericConnectionError);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = l10n.genericConnectionError;
      });
    }
  }

  Future<bool> _confirm(String title, String body) async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.confirm)),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _cancel() async {
    final l10n = AppLocalizations.of(context);
    if (!await _confirm(l10n.orderCancelTitle, l10n.orderCancelBody)) return;
    await _run(() => widget.repository.cancel(_order.id));
  }

  Future<void> _confirmInstallation() async {
    final l10n = AppLocalizations.of(context);
    if (!await _confirm(l10n.orderConfirmInstallTitle, l10n.orderConfirmInstallBody)) return;
    await _run(() => widget.repository.confirmInstallation(_order.id));
  }

  Future<void> _review(OrderLine line) async {
    final input = await showModalBottomSheet<(int, String)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReviewSheet(productName: line.nameFor(Localizations.localeOf(context).languageCode)),
    );
    if (input == null) return;
    await _run(() => widget.repository.submitReview(
          orderId: _order.id,
          productId: line.productId,
          rating: input.$1,
          comment: input.$2,
        ));
  }

  Future<void> _dispute() async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _DisputeSheet(),
    );
    if (reason == null) return;
    await _run(() => widget.repository.openDispute(orderId: _order.id, reason: reason));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final order = _order;
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSunken,
        elevation: 0,
        title: Text(order.vendorName, style: AppTypography.h1.copyWith(fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(l10n.orderNumber(order.id.substring(0, 8).toUpperCase()), style: AppTypography.cardTitle)),
                    OrderStatusChip(status: order.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (order.status == OrderStatus.cancelled)
                  Text(l10n.orderCancelledBody, style: AppTypography.bodyMuted)
                else
                  _Timeline(order: order),
              ],
            ),
          ),
          if (order.disputeStatus != null)
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.disputeStatus == 'open' ? l10n.orderDisputeOpen : l10n.orderDisputeClosed,
                    style: AppTypography.cardTitle,
                  ),
                  if ((order.disputeResolution ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(order.disputeResolution!, style: AppTypography.body),
                  ],
                ],
              ),
            ),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final line in order.items)
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
                              Text(line.nameFor(lang), style: AppTypography.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                              Text('${line.quantity} × ${formatMoney(line.unitPrice, order.currency)}', style: AppTypography.bodyMuted),
                              if (order.canReview)
                                order.reviewedProductIds.contains(line.productId)
                                    ? Text(l10n.orderReviewed, style: const TextStyle(color: AppColors.success, fontSize: 12))
                                    : InkWell(
                                        onTap: _busy ? null : () => _review(line),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Text(l10n.orderWriteReview, style: AppTypography.link),
                                        ),
                                      ),
                            ],
                          ),
                        ),
                        Text(formatMoney(line.lineTotal, order.currency), style: AppTypography.body),
                      ],
                    ),
                  ),
                const Divider(color: AppColors.line),
                _Row(l10n.checkoutDeliveryFee, order.deliveryFee == 0 ? l10n.checkoutFree : formatMoney(order.deliveryFee, order.currency)),
                _Row(l10n.checkoutTotal, formatMoney(order.total, order.currency), bold: true),
                const SizedBox(height: 4),
                Text(l10n.checkoutCashOnDelivery, style: AppTypography.bodyMuted),
              ],
            ),
          ),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.checkoutDeliveryDetails, style: AppTypography.cardTitle),
                const SizedBox(height: 6),
                Text(order.contactName, style: AppTypography.body),
                Text(formatPhone(order.contactPhone), style: AppTypography.bodyMuted),
                const SizedBox(height: 4),
                Text('${order.addressText}, ${order.city}', style: AppTypography.body),
                if (order.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(order.note, style: AppTypography.bodyMuted),
                ],
              ],
            ),
          ),
          if (_error != null) ...[FormErrorText(_error!), const SizedBox(height: AppSpacing.sm)],
          if (order.canConfirmInstallation) ...[
            PrimaryButton(label: l10n.orderConfirmInstall, busy: _busy, onPressed: _confirmInstallation),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (order.canCancel)
            OutlinedButton(onPressed: _busy ? null : _cancel, child: Text(l10n.orderCancel)),
          if (order.canOpenDispute)
            TextButton(onPressed: _busy ? null : _dispute, child: Text(l10n.orderReportProblem)),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final reached = OrderStatus.progression.indexOf(order.status);
    return Column(
      children: [
        for (var i = 0; i < OrderStatus.progression.length; i++)
          Builder(builder: (context) {
            final status = OrderStatus.progression[i];
            final done = i <= reached;
            final at = order.history.where((h) => h.status == status).map((h) => h.at).whereType<DateTime>().firstOrNull;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 18, color: done ? AppColors.success : AppColors.ink400),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(orderStatusLabel(l10n, status),
                        style: done ? AppTypography.body : AppTypography.bodyMuted),
                  ),
                  if (at != null) Text(formatOrderDate(at, locale), style: AppTypography.bodyMuted),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: AppShadows.card,
        ),
        child: child,
      );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold ? AppTypography.price : AppTypography.bodyMuted;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: style), Text(value, style: style)]),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );
}

/// Returns (stars, comment) or null.
class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.productName});

  final String productName;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _stars = 0;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SheetFrame(children: [
      Text(widget.productName, style: AppTypography.cardTitle),
      const SizedBox(height: AppSpacing.md),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 1; i <= 5; i++)
            IconButton(
              key: ValueKey('star-$i'),
              onPressed: () => setState(() => _stars = i),
              icon: Icon(i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded, color: AppColors.accent, size: 34),
            ),
        ],
      ),
      TextField(
        controller: _comment,
        maxLines: 3,
        maxLength: 1000,
        decoration: InputDecoration(hintText: l10n.orderReviewHint),
      ),
      const SizedBox(height: AppSpacing.sm),
      PrimaryButton(
        label: l10n.orderSubmitReview,
        onPressed: _stars == 0 ? null : () => Navigator.pop(context, (_stars, _comment.text.trim())),
      ),
    ]);
  }
}

class _DisputeSheet extends StatefulWidget {
  const _DisputeSheet();

  @override
  State<_DisputeSheet> createState() => _DisputeSheetState();
}

class _DisputeSheetState extends State<_DisputeSheet> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SheetFrame(children: [
      Text(l10n.orderReportProblem, style: AppTypography.cardTitle),
      const SizedBox(height: 4),
      Text(l10n.orderReportProblemBody, style: AppTypography.bodyMuted),
      const SizedBox(height: AppSpacing.md),
      TextField(controller: _reason, maxLines: 4, maxLength: 2000, onChanged: (_) => setState(() {})),
      const SizedBox(height: AppSpacing.sm),
      PrimaryButton(
        label: l10n.orderSendReport,
        onPressed: _reason.text.trim().length < 10 ? null : () => Navigator.pop(context, _reason.text.trim()),
      ),
    ]);
  }
}
