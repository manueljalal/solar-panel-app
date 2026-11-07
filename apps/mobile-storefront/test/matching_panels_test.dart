import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/features/home/domain/home_product.dart';
import 'package:solary_marketplace/features/wattage_calculator/presentation/matching_panels_screen.dart';

HomeProduct _p(String id, String spec) => HomeProduct(
      id: id, vendorId: 'v', priceValue: 0, currency: 'IQD', imageUrl: '', spec: spec,
      brand: '', title: id, vendor: 'v', price: '', rating: 0, sold: 0,
    );

void main() {
  test('only plain-wattage specs count as panels, closest to the target first', () {
    final items = [_p('inv', '6kW'), _p('bat', '5kWh'), _p('p400', '400W'), _p('p580', '580 w'), _p('p450', '450W')];
    expect(matchingPanels(items, 585).map((p) => p.id), ['p580', 'p450', 'p400']);
  });
}
