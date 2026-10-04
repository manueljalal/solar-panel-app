import 'package:flutter/foundation.dart';
import '../../home/domain/home_product.dart';
import '../domain/cart_item.dart';

/// Holds cart state for the whole app session. In-memory only — cleared on
/// app restart. That's a real limitation, not a placeholder pretending to
/// be done: once there's a checkout flow worth persisting, back this with
/// a Firestore `carts/{uid}` doc (the uid already exists — see
/// core/auth/auth_repository.dart) instead of rewriting the call sites
/// that use this controller.
///
/// A single instance is shared app-wide via CartScope (see
/// presentation/cart_scope.dart) so any screen can add/remove items and
/// any screen (the Cart tab, the nav badge) reflects it immediately.
class CartController extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0, (sum, item) => sum + item.lineTotal);

  bool get isEmpty => _items.isEmpty;

  void add(HomeProduct product, {int quantity = 1}) {
    final index = _items.indexWhere((i) => i.product.title == product.title);
    if (index == -1) {
      _items.add(CartItem(product: product, quantity: quantity));
    } else {
      _items[index] = _items[index].copyWith(quantity: _items[index].quantity + quantity);
    }
    notifyListeners();
  }

  void setQuantity(HomeProduct product, int quantity) {
    final index = _items.indexWhere((i) => i.product.title == product.title);
    if (index == -1) return;
    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index] = _items[index].copyWith(quantity: quantity);
    }
    notifyListeners();
  }

  void remove(HomeProduct product) {
    _items.removeWhere((i) => i.product.title == product.title);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
