import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../home/domain/home_product.dart';
import '../domain/cart_item.dart';
import 'cart_storage.dart';

/// Holds cart state for the whole app. With a [storage] (main.dart passes
/// SharedPrefsCartStorage) the cart is restored on launch and saved after
/// every change; without one (widget tests) it lives in memory only.
///
/// A single instance is shared app-wide via CartScope (see
/// presentation/cart_scope.dart) so any screen can add/remove items and
/// any screen (the Cart tab, the nav badge) reflects it immediately.
class CartController extends ChangeNotifier {
  CartController({CartStorage? storage}) : _storage = storage {
    if (storage != null) unawaited(_restore(storage));
  }

  final CartStorage? _storage;
  final List<CartItem> _items = [];
  bool _changedBeforeRestore = false;

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Sum of every line regardless of currency — kept for the single-currency
  /// case; prefer [totals] wherever a cart may mix USD and IQD.
  double get subtotal => _items.fold(0, (sum, item) => sum + item.lineTotal);

  Map<String, double> get totals {
    final out = <String, double>{};
    for (final item in _items) {
      out[item.currency] = (out[item.currency] ?? 0) + item.lineTotal;
    }
    return out;
  }

  bool get isEmpty => _items.isEmpty;

  static String _keyOf(HomeProduct product) => product.id.isNotEmpty ? product.id : product.title;

  int _indexOf(HomeProduct product) {
    final key = _keyOf(product);
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
    final key = _keyOf(product);
    _items.removeWhere((i) => i.key == key);
    _changed();
  }

  void clear() {
    _items.clear();
    _changed();
  }

  void _changed() {
    _changedBeforeRestore = true;
    notifyListeners();
    final storage = _storage;
    if (storage != null) unawaited(storage.save(List.of(_items)).catchError((Object _) {}));
  }

  Future<void> _restore(CartStorage storage) async {
    final List<CartItem> saved;
    try {
      saved = await storage.load();
    } catch (_) {
      return;
    }
    // Anything added while the saved cart was still loading wins — merge
    // the saved lines in behind it instead of overwriting.
    final hadChanges = _changedBeforeRestore;
    for (final item in saved) {
      if (_items.any((i) => i.key == item.key)) continue;
      _items.add(item);
    }
    if (saved.isNotEmpty) notifyListeners();
    if (hadChanges && saved.isNotEmpty) unawaited(storage.save(List.of(_items)).catchError((Object _) {}));
  }
}
