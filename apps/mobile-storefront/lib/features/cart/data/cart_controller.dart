import 'package:flutter/foundation.dart';
import '../../home/domain/home_product.dart';
import '../domain/cart_item.dart';

/// Holds cart state for the whole app session (in memory — cleared on app
/// restart). Checkout sends product ids and quantities; prices are always
/// re-read on the server.
///
/// A single instance is shared app-wide via CartScope (see
/// presentation/cart_scope.dart) so any screen can add/remove items and
/// any screen (the Cart tab, the nav badge) reflects it immediately.
class CartController extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Totals per currency — USD and IQD products are never added together.
  Map<String, double> get totals {
    final out = <String, double>{};
    for (final i in _items) {
      out[i.currency] = (out[i.currency] ?? 0) + i.lineTotal;
    }
    return out;
  }

  // Lines are keyed by product id (two products can share a name); test
  // fixtures without ids fall back to the title.
  static String _key(HomeProduct p) => p.id.isNotEmpty ? p.id : p.title;

  bool get isEmpty => _items.isEmpty;

  void add(HomeProduct product, {int quantity = 1}) {
    final index = _items.indexWhere((i) => _key(i.product) == _key(product));
    if (index == -1) {
      _items.add(CartItem(product: product, quantity: quantity));
    } else {
      _items[index] = _items[index].copyWith(quantity: _items[index].quantity + quantity);
    }
    notifyListeners();
  }

  void setQuantity(HomeProduct product, int quantity) {
    final index = _items.indexWhere((i) => _key(i.product) == _key(product));
    if (index == -1) return;
    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index] = _items[index].copyWith(quantity: quantity);
    }
    notifyListeners();
  }

  void remove(HomeProduct product) {
    _items.removeWhere((i) => _key(i.product) == _key(product));
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
