import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../domain/cart_item.dart';

/// Where the cart survives app restarts. On-device rather than a Firestore
/// `carts/{uid}` doc: a guest's anonymous uid changes on sign-in/sign-out,
/// and the cart should follow the device, not the account.
abstract class CartStore {
  Future<List<CartItem>> load();
  Future<void> save(List<CartItem> items);
}

class SharedPrefsCartStore implements CartStore {
  static const _key = 'cart.v1';

  @override
  Future<List<CartItem>> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return [];
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return list.map(CartItem.fromJson).whereType<CartItem>().toList();
    } catch (_) {
      // A corrupt or old-format cart is dropped, never a crash.
      return [];
    }
  }

  @override
  Future<void> save(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map((i) => i.toJson()).toList()));
  }
}
