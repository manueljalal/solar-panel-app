import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/formatting/money.dart';
import '../data/order_repository.dart';
import '../domain/order.dart';
import 'order_detail_screen.dart';
import 'widgets/order_status_chip.dart';

/// Orders tab — a live query of the signed-in customer's `orders` docs
/// (rules allow reading only your own). Follows auth state so the list
/// appears as soon as the silent anonymous sign-in in main.dart resolves.
///
/// With no Firebase app (widget tests) or no user yet it shows the empty
/// state. Tests that need a list pass [repository] and [uid].
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key, this.repository, this.uid});

  final OrderRepository? repository;
  final String? uid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final Widget body;
    if (uid != null && repository != null) {
      body = _OrderList(repository: repository!, uid: uid!);
    } else if (Firebase.apps.isEmpty) {
      body = const _EmptyOrders();
    } else {
      body = StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          final user = snap.data;
          if (user == null) return const _EmptyOrders();
          return _OrderList(repository: repository ?? OrderRepository(), uid: user.uid);
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSunken,
        elevation: 0,
        title: Text(l10n.ordersTitle, style: AppTypography.h1.copyWith(fontSize: 20)),
        centerTitle: false,
      ),
      body: body,
    );
  }
}

class _OrderList extends StatefulWidget {
  const _OrderList({required this.repository, required this.uid});

  final OrderRepository repository;
  final String uid;

  @override
  State<_OrderList> createState() => _OrderListState();
}

class _OrderListState extends State<_OrderList> {
  late Stream<List<CustomerOrder>> _orders = widget.repository.watchMyOrders(widget.uid);

  @override
  void didUpdateWidget(_OrderList old) {
    super.didUpdateWidget(old);
    if (old.uid != widget.uid) _orders = widget.repository.watchMyOrders(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<List<CustomerOrder>>(
      stream: _orders,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.ordersLoadError, style: AppTypography.bodyMuted),
                TextButton(
                  onPressed: () => setState(() => _orders = widget.repository.watchMyOrders(widget.uid)),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          );
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final orders = snap.data!;
        if (orders.isEmpty) return const _EmptyOrders();
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: orders.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, i) => _OrderRow(order: orders[i], repository: widget.repository),
        );
      },
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.repository});

  final CustomerOrder order;
  final OrderRepository repository;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final first = order.lines.isEmpty ? '' : order.lines.first.nameFor(languageCode);
    final more = order.lines.length > 1 ? ' +${order.lines.length - 1}' : '';

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => OrderDetailScreen(order: order, repository: repository)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(l10n.orderNumber(order.shortId), style: AppTypography.cardTitle)),
                  OrderStatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('$first$more', style: AppTypography.body, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      [
                        if (order.createdAt != null) formatOrderDate(order.createdAt!),
                        l10n.orderItemCount(order.itemCount),
                      ].join(' · '),
                      style: AppTypography.bodyMuted,
                    ),
                  ),
                  Text(formatTotals(order.totals), style: AppTypography.price),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "2026-10-23". Numeric on purpose: intl has no date symbols for Sorani
/// (ckb), so a localized month name would crash or fall back to English.
String formatOrderDate(DateTime date) {
  final d = date.toLocal();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.ink400),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.ordersEmptyTitle, style: AppTypography.cardTitle),
            const SizedBox(height: 4),
            Text(l10n.ordersEmptyBody, textAlign: TextAlign.center, style: AppTypography.bodyMuted),
          ],
        ),
      ),
    );
  }
}
