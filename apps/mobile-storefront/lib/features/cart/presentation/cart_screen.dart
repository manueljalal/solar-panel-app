import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/navigation/root_shell.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/formatting/money.dart';
import '../../../shared/widgets/placeholder_image.dart';
import '../../checkout/presentation/checkout_screen.dart';
import '../../checkout/presentation/order_placed_screen.dart';
import '../../orders/data/order_repository.dart';
import '../data/cart_scope.dart';
import '../domain/cart_item.dart';

/// Real cart screen — reads live from CartScope, so it always reflects
/// whatever was added from product detail. Quantity can be changed or
/// removed inline; "Checkout" opens CheckoutScreen, and after a placed
/// order this screen shows the confirmation and can jump to the Orders tab.
///
/// [orderRepository] passes through to CheckoutScreen for widget tests.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key, this.orderRepository});

  final OrderRepository? orderRepository;

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSunken,
        elevation: 0,
        title: Text(AppLocalizations.of(context).cartTitle, style: AppTypography.h1.copyWith(fontSize: 20)),
        centerTitle: false,
      ),
      body: AnimatedBuilder(
        animation: cart,
        builder: (context, _) {
          if (cart.isEmpty) return const _EmptyCart();

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) => _CartRow(item: cart.items[i]),
                ),
              ),
              _CartSummary(
                totals: cart.totals,
                itemCount: cart.itemCount,
                onCheckout: () => _checkout(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _checkout(BuildContext context) async {
    final orderId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => CheckoutScreen(repository: orderRepository)),
    );
    if (orderId == null || !context.mounted) return;
    final viewOrders = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => OrderPlacedScreen(orderId: orderId)),
    );
    if (viewOrders == true && context.mounted) RootShell.showTab(context, RootShell.ordersTab);
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 40, color: AppColors.ink400),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.cartEmptyTitle, style: AppTypography.cardTitle),
            const SizedBox(height: 4),
            Text(
              l10n.cartEmptyBody,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            child: SizedBox(
              width: 72,
              height: 72,
              child: NetworkImageWithFallback(url: item.product.imageUrl, fallbackIcon: Icons.solar_power_outlined),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.title, style: AppTypography.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(item.product.vendor, style: AppTypography.bodyMuted),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _QtyButton(icon: Icons.remove, onTap: () => cart.setQuantity(item.product, item.quantity - 1)),
                    SizedBox(
                      width: 32,
                      child: Text('${item.quantity}', textAlign: TextAlign.center, style: AppTypography.cardTitle),
                    ),
                    _QtyButton(icon: Icons.add, onTap: () => cart.setQuantity(item.product, item.quantity + 1)),
                    const Spacer(),
                    Text(item.product.price, style: AppTypography.price),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.ink400),
            onPressed: () => cart.remove(item.product),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 28, height: 28, child: Icon(icon, size: 15, color: AppColors.ink900)),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.totals, required this.itemCount, required this.onCheckout});

  final Map<String, double> totals;
  final int itemCount;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.cartSubtotal(itemCount), style: AppTypography.bodyMuted),
                  const SizedBox(width: AppSpacing.md),
                  Flexible(child: Text(formatTotals(totals), style: AppTypography.price, textAlign: TextAlign.end)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: onCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.chip)),
                ),
                child: Text(l10n.checkout, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
