import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/features/cart/data/cart_controller.dart';
import 'package:solary_marketplace/features/home/domain/home_product.dart';
import 'package:solary_marketplace/shared/money.dart';

// Strip the invisible left-to-right isolate marks formatMoney adds.
String plain(String s) => s.replaceAll(RegExp('[\u2066\u2069]'), '');

HomeProduct product(String id, String title, double price, String currency) => HomeProduct(
      id: id,
      title: title,
      priceValue: price,
      currency: currency,
      price: '',
      imageUrl: '',
      spec: '',
      brand: '',
      vendor: 'V',
      rating: 0,
      sold: 0,
    );

void main() {
  test('formatMoney groups thousands and places the currency', () {
    expect(plain(formatMoney(189, 'USD')), r'$189');
    expect(plain(formatMoney(1240.5, 'USD')), r'$1,240.50');
    expect(plain(formatMoney(400000, 'IQD')), 'IQD 400,000');
  });

  test('cart keeps USD and IQD totals separate', () {
    final cart = CartController()
      ..add(product('a', 'Panel', 150, 'USD'), quantity: 2)
      ..add(product('b', 'Cable', 25000, 'IQD'));
    expect(cart.totals, {'USD': 300.0, 'IQD': 25000.0});
    expect(cart.itemCount, 3);
  });

  test('two products with the same name stay separate cart lines', () {
    final cart = CartController()
      ..add(product('a', 'Panel', 150, 'USD'))
      ..add(product('b', 'Panel', 160, 'USD'))
      ..add(product('a', 'Panel', 150, 'USD'));
    expect(cart.items.length, 2);
    expect(cart.items.firstWhere((i) => i.product.id == 'a').quantity, 2);
  });
}
