import 'package:flutter/foundation.dart';
import '../../home/domain/home_product.dart';
import '../domain/cart_item.dart';
import 'cart_store.dart';

/// Holds cart state for the whole app. Persisted on-device through
/// [CartStore] when one is given (main.dart passes SharedPrefsCartStore;
/// widget tests pass none and get a purely in-memory cart).
///
/// A single instance is shared app-wide via CartScope (see
/// data/cart_scope.dart) so any screen can add/remove items and any screen
/// (the Cart tab, the nav badge) reflects it immediately.
class CartController extends ChangeNotifier {
  CartController({CartStore? store}) : _store = store;

  final CartStore? _store;
  final List<CartItem> _items = [];

  /// Restores the saved cart. Items added before this finishes are kept
  /// (merged on top), so a fast tap during startup isn't lost.
  Future<void> restore() async {
    final store = _store;
    if (store == null) return;
    final saved = await store.load();
    if (saved.isEmpty) return;
    for (final item in saved) {
      if (_indexOf(item.product) == -1) _items.add(item);
    }
    notifyListeners();
  }

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Totals per currency — a cart can mix USD and IQD products, and adding
  /// those together would be meaningless.
  Map<String, double> get subtotals {
    final out = <String, double>{};
    for (final item in _items) {
      out[item.currency] = (out[item.currency] ?? 0) + item.lineTotal;
    }
    return out;
  }

  /// Single-currency convenience (the common case).
  double get subtotal => _items.fold(0, (sum, item) => sum + item.lineTotal);

  bool get isEmpty => _items.isEmpty;

  int _indexOf(HomeProduct product) {
    final key = product.id.isNotEmpty ? product.id : product.title;
    return _items.indexWhere((i) => i.key == key);
  }

  void add(HomeProduct product, {int quantity = 1}) {
    final index = _indexOf(product);
    if (index == -1) {
      _items.add(CartItem(product: product, quantity: quantity));
    } else {
      _items[index] = _items[index].copyWith(quantity: _items[index].quantity + quantity);
    }
    _changed();
  }

  void setQuantity(HomeProduct product, int quantity) {
    final index = _indexOf(product);
    if (index == -1) return;
    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index] = _items[index].copyWith(quantity: quantity);
    }
    _changed();
  }

  void remove(HomeProduct product) {
    final index = _indexOf(product);
    if (index != -1) _items.removeAt(index);
    _changed();
  }

  void clear() {
    _items.clear();
    _changed();
  }

  void _changed() {
    notifyListeners();
    _store?.save(List.of(_items));
  }
}
