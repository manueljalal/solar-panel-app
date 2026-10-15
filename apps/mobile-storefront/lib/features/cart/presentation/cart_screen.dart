import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/navigation/root_shell.dart';
import '../../../shared/widgets/placeholder_image.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../checkout/presentation/checkout_screen.dart';
import '../../home/domain/home_product.dart';
import '../data/cart_scope.dart';
import '../domain/cart_item.dart';

/// Cart screen — reads live from CartScope, so it always reflects whatever
/// was added from product detail. Quantity can be changed or removed
/// inline; "Checkout" opens CheckoutScreen and, once the order is placed,
/// jumps to the Orders tab.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

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
              _CartSummary(subtotals: cart.subtotals, itemCount: cart.itemCount),
            ],
          );
        },
      ),
    );
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
                Text(item.product.titleFor(Localizations.localeOf(context).languageCode), style: AppTypography.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
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
  const _CartSummary({required this.subtotals, required this.itemCount});

  final Map<String, double> subtotals;
  final int itemCount;

  Future<void> _checkout(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final placed = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
    if (placed == null || !context.mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(l10n.checkoutSuccess(placed.length))));
    RootShell.selectTab(context, RootShell.ordersTab);
  }

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
                  Text(
                    subtotals.entries.map((e) => formatMoney(e.value, e.key)).join(' + '),
                    style: AppTypography.price,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(label: l10n.checkout, onPressed: () => _checkout(context)),
            ],
          ),
        ),
      ),
    );
  }
}
