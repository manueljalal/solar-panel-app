import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'solary_favorites';

/// Product ids the shopper hearted. Kept on the device (works for guests);
/// shown in Account → Favourites.
class FavoritesController extends ValueNotifier<Set<String>> {
  FavoritesController._() : super(const {}) {
    _restore();
  }

  static final instance = FavoritesController._();

  bool contains(String productId) => value.contains(productId);

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      value = (prefs.getStringList(_prefsKey) ?? const []).toSet();
    } catch (_) {
      // No storage (e.g. widget tests): start empty.
    }
  }

  Future<void> toggle(String productId) async {
    if (productId.isEmpty) return;
    final next = {...value};
    if (!next.remove(productId)) next.add(productId);
    value = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, next.toList());
    } catch (_) {}
  }
}
