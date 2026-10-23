import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../domain/cart_item.dart';

/// Where CartController saves the cart between launches.
abstract class CartStorage {
  Future<List<CartItem>> load();
  Future<void> save(List<CartItem> items);
}

/// Saves the cart on the device. Local rather than a Firestore `carts/{uid}`
/// doc on purpose: a guest's anonymous uid is tied to this install anyway,
/// so a server copy would add a read on every launch and a write on every
/// tap without syncing anywhere new. Revisit once accounts span devices.
class SharedPrefsCartStorage implements CartStorage {
  static const _key = 'cart.v1';

  @override
  Future<List<CartItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.map(CartItem.fromJson).whereType<CartItem>().toList();
    } on FormatException {
      // A corrupt saved cart shouldn't block the app — start empty.
      return [];
    }
  }

  @override
  Future<void> save(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode([for (final item in items) item.toJson()]));
  }
}
