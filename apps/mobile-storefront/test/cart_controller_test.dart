import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/features/cart/data/cart_controller.dart';
import 'package:solary_marketplace/features/cart/data/cart_storage.dart';
import 'package:solary_marketplace/features/cart/domain/cart_item.dart';
import 'package:solary_marketplace/features/home/domain/home_product.dart';

/// Round-trips through JSON like the real SharedPrefsCartStorage does.
class _MemoryCartStorage implements CartStorage {
  List<Object?> saved = [];

  @override
  Future<List<CartItem>> load() async => saved.map(CartItem.fromJson).whereType<CartItem>().toList();

  @override
  Future<void> save(List<CartItem> items) async => saved = [for (final i in items) i.toJson()];
}

const _panel = HomeProduct(
  id: 'p1',
  vendorId: 'v1',
  priceValue: 189,
  imageUrl: '',
  spec: '450W',
  brand: 'JinkoSolar',
  title: 'Tiger Neo',
  vendor: 'SunBridge',
  price: '\$189',
  rating: 4.9,
  sold: 3,
);
const _kit = HomeProduct(
  id: 'p2',
  priceValue: 250000,
  currency: 'IQD',
  imageUrl: '',
  spec: '',
  brand: '',
  title: 'Mounting kit',
  vendor: 'SunBridge',
  price: 'IQD 250000',
  rating: 0,
  sold: 0,
);

void main() {
  test('cart survives a restart via its storage', () async {
    final storage = _MemoryCartStorage();
    final first = CartController(storage: storage)
      ..add(_panel)
      ..add(_panel)
      ..add(_kit);
    await Future<void>.delayed(Duration.zero);
    first.dispose();

    final second = CartController(storage: storage);
    await Future<void>.delayed(Duration.zero);
    expect(second.itemCount, 3);
    expect(second.items.first.product.id, 'p1');
    expect(second.items.first.quantity, 2);
    expect(second.totals, {'USD': 378.0, 'IQD': 250000.0});
  });

  test('items added before the saved cart loads are kept', () async {
    final storage = _MemoryCartStorage();
    await storage.save([const CartItem(product: _kit, quantity: 1)]);

    final cart = CartController(storage: storage)..add(_panel);
    await Future<void>.delayed(Duration.zero);
    expect(cart.items.map((i) => i.product.id), ['p1', 'p2']);
  });

  test('lines are keyed by product id, not title', () {
    final cart = CartController()
      ..add(_panel)
      ..add(const HomeProduct(
        id: 'p3',
        imageUrl: '',
        spec: '',
        brand: '',
        title: 'Tiger Neo', // same title, different product
        vendor: 'Other vendor',
        price: '\$150',
        rating: 0,
        sold: 0,
      ));
    expect(cart.items, hasLength(2));
  });
}
