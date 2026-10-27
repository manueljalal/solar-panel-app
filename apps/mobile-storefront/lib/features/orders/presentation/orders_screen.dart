import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../../core/auth/friendly_function_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/money.dart';
import '../../account/presentation/sign_in_screen.dart';
import '../data/orders_repository.dart';
import '../domain/order.dart';

/// Orders tab: the signed-in customer's cash-on-delivery orders, newest
/// first, with status. Tapping one shows its items and address, and lets
/// the customer cancel while the seller hasn't confirmed it yet. Reloads
/// whenever an order is placed or cancelled elsewhere in the app.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, this.status, OrdersRepository? repository}) : _repository = repository;

  /// Show only orders in this status (from Account's order tracker); null = all.
  final OrderStatus? status;
  final OrdersRepository? _repository;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late final OrdersRepository _repo = widget._repository ?? OrdersRepository();
  Future<List<CustomerOrder>>? _orders;

  User? get _user => Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser;
  bool get _hasAccount => _user != null && !_user!.isAnonymous;

  @override
  void initState() {
    super.initState();
    OrdersRepository.changes.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    OrdersRepository.changes.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    // Block body: an arrow here would return the Future from setState's
    // callback, which Flutter rejects with a red error screen.
    final next = _hasAccount ? _repo.listMine() : null;
    setState(() {
      _orders = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.status == null ? l10n.ordersTitle : statusLabel(l10n, widget.status!),
          style: AppTypography.h1.copyWith(fontSize: 20),
        ),
        centerTitle: false,
      ),
      body: !_hasAccount
          ? _Message(
              icon: Icons.person_outline,
              title: l10n.ordersSignInTitle,
              body: l10n.checkoutSignInBody,
              action: TextButton(
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignInScreen()));
                  _reload();
                },
                child: Text(l10n.accountSignIn),
              ),
            )
          : FutureBuilder<List<CustomerOrder>>(
              future: _orders,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return _Message(
                    icon: Icons.cloud_off_outlined,
                    title: l10n.homeLoadError,
                    action: TextButton(onPressed: _reload, child: Text(l10n.retry)),
                  );
                }
                final orders = [
                  for (final o in snap.data ?? const <CustomerOrder>[])
                    if (widget.status == null || o.status == widget.status) o,
                ];
                if (orders.isEmpty) {
                  return _Message(
                    icon: Icons.inventory_2_outlined,
                    title: l10n.ordersEmptyTitle,
                    body: l10n.ordersEmptyBody,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    _reload();
                    await _orders;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) => _OrderCard(order: orders[i], onTap: () => _showDetail(orders[i])),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showDetail(CustomerOrder order) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card))),
      builder: (_) => _OrderDetail(order: order, repository: _repo),
    );
  }
}

String statusLabel(AppLocalizations l10n, OrderStatus s) => switch (s) {
      OrderStatus.placed => l10n.orderStatusPlaced,
      OrderStatus.confirmed => l10n.orderStatusConfirmed,
      OrderStatus.outForDelivery => l10n.orderStatusOutForDelivery,
      OrderStatus.delivered => l10n.orderStatusDelivered,
      OrderStatus.cancelled => l10n.orderStatusCancelled,
    };

Color _statusColor(OrderStatus s) => switch (s) {
      OrderStatus.placed => AppColors.accent,
      OrderStatus.confirmed || OrderStatus.outForDelivery => AppColors.primary,
      OrderStatus.delivered => AppColors.success,
      OrderStatus.cancelled => AppColors.ink400,
    };

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadii.chip)),
      child: Text(
        statusLabel(AppLocalizations.of(context), status),
        style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final CustomerOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final date = MaterialLocalizations.of(context).formatMediumDate(order.createdAt);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(order.vendorName, style: AppTypography.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                _StatusChip(order.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              order.items.map((i) => i.name).join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('$date · ${l10n.orderItemCount(order.itemCount)}', style: AppTypography.bodyMuted.copyWith(fontSize: 12.5)),
                const Spacer(),
                Text(formatTotals(order.totals), style: AppTypography.cardTitle.copyWith(color: AppColors.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderDetail extends StatefulWidget {
  const _OrderDetail({required this.order, required this.repository});

  final CustomerOrder order;
  final OrdersRepository repository;

  @override
  State<_OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends State<_OrderDetail> {
  bool _busy = false;

  Future<void> _cancel() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.orderCancelConfirmTitle),
        content: Text(l10n.orderCancelConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.orderKeep)),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.orderCancel)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.repository.cancel(widget.order.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.orderCancelledToast)));
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(friendlyFunctionError(e, l10n.orderActionFailed))));
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.orderActionFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final o = widget.order;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: Text(o.vendorName, style: AppTypography.h1.copyWith(fontSize: 19))),
                _StatusChip(o.status),
              ],
            ),
            if (o.status == OrderStatus.cancelled && (o.cancelReason ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(l10n.orderCancelReason(o.cancelReason!), style: AppTypography.bodyMuted),
            ],
            const SizedBox(height: AppSpacing.lg),
            for (final i in o.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text('${i.qty} × ${i.name}', style: AppTypography.body)),
                    Text(formatMoney(i.lineTotal, i.currency), style: AppTypography.body),
                  ],
                ),
              ),
            const Divider(color: AppColors.line),
            Row(
              children: [
                Expanded(child: Text(l10n.checkoutTotal, style: AppTypography.cardTitle)),
                Text(formatTotals(o.totals), style: AppTypography.price),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.orderDeliverTo, style: AppTypography.bodyMuted.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(o.address, style: AppTypography.body),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(Icons.payments_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(l10n.checkoutCod, style: AppTypography.body),
              ],
            ),
            if (o.canCancel) ...[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _busy ? null : _cancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    side: const BorderSide(color: AppColors.line),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(l10n.orderCancel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, this.body, this.action});

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.primary.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTypography.cardTitle, textAlign: TextAlign.center),
            if (body != null) ...[
              const SizedBox(height: 4),
              Text(body!, textAlign: TextAlign.center, style: AppTypography.bodyMuted),
            ],
            if (action != null) ...[const SizedBox(height: AppSpacing.sm), action!],
          ],
        ),
      ),
    );
  }
}
