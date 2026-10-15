import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/domain/home_product.dart';
import '../data/orders_repository.dart';
import '../domain/order.dart';
import 'order_detail_screen.dart';
import 'order_status_label.dart';

/// Orders tab — the caller's orders from storefront-listMyOrders, newest
/// first. Reloads whenever OrdersRepository.changes ticks (checkout,
/// cancel, confirm…) and on pull-to-refresh.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, this.repository});

  final OrdersRepository? repository;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  // Lazily built: this tab can be constructed in widget tests where
  // Firebase was never initialized.
  OrdersRepository? _repository;
  OrdersRepository get _repo => _repository ??= widget.repository ?? OrdersRepository();

  List<CustomerOrder>? _orders;
  bool _failed = false;

  bool get _firebaseReady => widget.repository != null || Firebase.apps.isNotEmpty;

  @override
  void initState() {
    super.initState();
    OrdersRepository.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    OrdersRepository.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!_firebaseReady) {
      setState(() => _orders = const []);
      return;
    }
    try {
      final orders = await _repo.listMyOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final orders = _orders;

    Widget body;
    if (orders == null && !_failed) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_failed && orders == null) {
      body = _Message(
        icon: Icons.cloud_off_outlined,
        title: l10n.homeLoadError,
        action: TextButton(onPressed: _load, child: Text(l10n.retry)),
      );
    } else if (orders!.isEmpty) {
      body = _Message(icon: Icons.inventory_2_outlined, title: l10n.ordersEmptyTitle, body: l10n.ordersEmptyBody);
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: orders.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, i) => _OrderCard(
            order: orders[i],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => OrderDetailScreen(order: orders[i], repository: _repo)),
            ),
          ),
        ),
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

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final CustomerOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(order.vendorName, style: AppTypography.cardTitle)),
                  OrderStatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                [
                  l10n.ordersItemCount(order.itemCount),
                  if (order.createdAt != null) formatOrderDate(order.createdAt!, locale),
                ].join(' · '),
                style: AppTypography.bodyMuted,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(formatMoney(order.total, order.currency), style: AppTypography.price),
                  const Spacer(),
                  if (order.disputeStatus == 'open')
                    Text(l10n.orderDisputeOpen, style: const TextStyle(color: AppColors.warning, fontSize: 12)),
                ],
              ),
            ],
          ),
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
            Icon(icon, size: 40, color: AppColors.ink400),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTypography.cardTitle, textAlign: TextAlign.center),
            if (body != null) ...[
              const SizedBox(height: 4),
              Text(body!, textAlign: TextAlign.center, style: AppTypography.bodyMuted),
            ],
            ?action,
          ],
        ),
      ),
    );
  }
}
