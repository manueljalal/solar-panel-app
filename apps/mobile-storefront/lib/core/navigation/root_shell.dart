import 'package:flutter/material.dart';
import '../../features/account/presentation/account_screen.dart';
import '../../features/cart/data/cart_scope.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/home/data/home_repository.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/learn/presentation/learn_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// Owns the bottom nav and switches between the 5 top-level tabs. Replaces
/// the old setup where HomeScreen carried its own BottomNavigationBar and
/// tapping any tab but Home did nothing — every tab now points at a real
/// screen.
///
/// Uses IndexedStack (not a fresh screen per tap) so each tab keeps its
/// scroll position/state when you switch away and back, which is the
/// behavior users expect from a bottom-nav app.
///
/// [homeRepository] threads through to the Home tab the same way it used
/// to reach HomeScreen directly, so widget tests can still inject a fake.
class RootShell extends StatefulWidget {
  const RootShell({super.key, this.homeRepository});

  final HomeRepository? homeRepository;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  late final _tabs = [
    HomeScreen(repository: widget.homeRepository),
    const LearnScreen(),
    const CartScreen(),
    const OrdersScreen(),
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: AnimatedBuilder(
        animation: cart,
        builder: (context, _) {
          return BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.ink900,
            unselectedItemColor: AppColors.ink400,
            selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            elevation: 0,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home), label: l10n.navHome),
              BottomNavigationBarItem(icon: const Icon(Icons.menu_book_outlined), label: l10n.navLearn),
              BottomNavigationBarItem(
                icon: _CartIcon(count: cart.itemCount),
                label: l10n.navCart,
              ),
              BottomNavigationBarItem(icon: const Icon(Icons.inventory_2_outlined), label: l10n.navOrders),
              BottomNavigationBarItem(icon: const Icon(Icons.person_outline), label: l10n.navAccount),
            ],
          );
        },
      ),
    );
  }
}

/// Cart tab icon with a real item-count badge — reflects CartController
/// live, so adding something from product detail updates the nav bar
/// immediately without navigating anywhere.
class _CartIcon extends StatelessWidget {
  const _CartIcon({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const Icon(Icons.shopping_cart_outlined);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.shopping_cart_outlined),
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            constraints: const BoxConstraints(minWidth: 15),
            decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
