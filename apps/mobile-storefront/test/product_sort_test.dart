import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/features/home/domain/home_product.dart';
import 'package:solary_marketplace/features/home/presentation/widgets/filter_chip_row.dart';

HomeProduct _p(String id, {double price = 0, String currency = 'IQD', double rating = 0, int sold = 0}) => HomeProduct(
      id: id,
      vendorId: 'v',
      priceValue: price,
      currency: currency,
      imageUrl: '',
      spec: '',
      brand: '',
      title: id,
      vendor: 'v',
      price: '',
      rating: rating,
      sold: sold,
    );

void main() {
  final items = [
    _p('cheap-iqd', price: 100000, sold: 5, rating: 4),
    _p('usd-200', price: 200, currency: 'USD', sold: 9, rating: 0),
    _p('dear-iqd', price: 500000, sold: 1, rating: 4.8),
  ];
  List<String> ids(ProductSort s) => sortProducts(items, s).map((p) => p.id).toList();

  test('best selling orders by units sold', () {
    expect(ids(ProductSort.bestSelling), ['usd-200', 'cheap-iqd', 'dear-iqd']);
  });
  test('top rated puts unrated products last', () {
    expect(ids(ProductSort.topRated), ['dear-iqd', 'cheap-iqd', 'usd-200']);
  });
  test('price sorts compare USD and IQD in one order', () {
    // \$200 ≈ 262,000 IQD — between the two IQD prices.
    expect(ids(ProductSort.priceLow), ['cheap-iqd', 'usd-200', 'dear-iqd']);
    expect(ids(ProductSort.priceHigh), ['dear-iqd', 'usd-200', 'cheap-iqd']);
  });
}
