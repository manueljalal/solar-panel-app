import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/features/cart/data/cart_controller.dart';
import 'package:solary_marketplace/features/cart/data/cart_store.dart';
import 'package:solary_marketplace/features/cart/domain/cart_item.dart';
import 'package:solary_marketplace/features/home/domain/home_product.dart';

import 'support/home_fixtures.dart';

class _MemoryStore implements CartStore {
  List<CartItem> saved = [];

  @override
  Future<List<CartItem>> load() async => saved;

  @override
  Future<void> save(List<CartItem> items) async => saved = items;
}

const _iqdProduct = HomeProduct(
  id: 'p-iqd',
  vendorId: 'v9',
  imageUrl: '',
  spec: '5kWh',
  brand: 'Local',
  title: 'Battery IQD',
  vendor: 'Basra Solar',
  price: 'IQD 900,000',
  priceValue: 900000,
  currency: 'IQD',
  rating: 0,
  sold: 0,
);

void main() {
  test('cart lines round-trip through JSON with id, vendor and numeric price', () {
    final item = CartItem(product: homeProducts[1], quantity: 2);
    final back = CartItem.fromJson(item.toJson())!;
    expect(back.product.id, 'p2');
    expect(back.product.vendorId, 'v2');
    expect(back.unitPrice, 1240);
    expect(back.quantity, 2);
    expect(CartItem.fromJson({'quantity': 0}), isNull);
    expect(CartItem.fromJson('garbage'), isNull);
  });

  test('controller saves every change and restores on a new instance', () async {
    final store = _MemoryStore();
    final cart = CartController(store: store)
      ..add(homeProducts[0])
      ..add(homeProducts[0])
      ..add(homeProducts[2]);
    await Future<void>.delayed(Duration.zero);
    expect(store.saved.length, 2);

    final restored = CartController(store: store);
    await restored.restore();
    expect(restored.itemCount, 3);
    expect(restored.items.first.quantity, 2);

    cart.clear();
    await Future<void>.delayed(Duration.zero);
    expect(store.saved, isEmpty);
  });

  test('subtotals are kept per currency, never summed across them', () {
    final cart = CartController()
      ..add(homeProducts[0], quantity: 2) // $189 × 2
      ..add(_iqdProduct);
    expect(cart.subtotals, {'USD': 378, 'IQD': 900000});
  });

  test('formatMoney groups thousands and keeps cents only when needed', () {
    expect(formatMoney(1240, 'USD'), '\$1,240');
    expect(formatMoney(120.5, 'USD'), '\$120.50');
    expect(formatMoney(905000, 'IQD'), 'IQD 905,000');
  });
}
