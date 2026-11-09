import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/features/home/domain/home_product.dart';
import 'package:solary_marketplace/features/wattage_calculator/data/calculator_repository.dart';
import 'package:solary_marketplace/features/wattage_calculator/domain/solar_sizing.dart';

HomeProduct _p(String id, double price, String currency, {bool inStock = true}) => HomeProduct(
      id: id, vendorId: 'v', priceValue: price, currency: currency, imageUrl: '', spec: '', brand: '',
      title: id, vendor: 'v', price: '', rating: 0, sold: 0, inStock: inStock,
    );

PackageOffer _offer(String id, SystemType type, double kw, {bool inStock = true}) => PackageOffer(
      package: SolarPackage(id: id, names: {'en': id}, systemType: type, sizeKw: kw, batteryKwh: null, items: const []),
      lines: [
        (product: _p('panel', 100000, 'IQD'), qty: 10),
        (product: _p('inverter', 900, 'USD', inStock: inStock), qty: 1),
      ],
    );

void main() {
  test('packages: same system type only, closest size first, bigger wins a tie', () {
    final offers = [
      _offer('h5', SystemType.hybrid, 5),
      _offer('h10', SystemType.hybrid, 10),
      _offer('h6', SystemType.hybrid, 6),
      _offer('og8', SystemType.onGrid, 8),
      _offer('h4', SystemType.hybrid, 4),
    ];
    final picked = recommendPackages(offers, SystemType.hybrid, 5).map((o) => o.package.id).toList();
    expect(picked, ['h5', 'h6', 'h4']);
    expect(recommendPackages(offers, SystemType.offGrid, 5), isEmpty);
  });

  test('package totals stay per currency; any out-of-stock item blocks it', () {
    final o = _offer('x', SystemType.onGrid, 5);
    expect(o.totals, {'IQD': 1000000, 'USD': 900});
    expect(o.inStock, isTrue);
    expect(_offer('y', SystemType.onGrid, 5, inStock: false).inStock, isFalse);
  });

  test('admin settings change the sizing; missing values fall back to defaults', () {
    const input = SizingInput(type: SystemType.onGrid, phase: Phase.single, dayLoadKw: 5);
    expect(SolarSizing.calculate(input).panelCount, 11); // defaults: 585 W, 25%
    final custom = SizingConfig.fromMap({'panelWattage': 450, 'lossMarginPercent': 0});
    // 5 kW, no margin → ceil(5000 / 450) = 12 panels.
    expect(SolarSizing.calculate(input, custom).panelCount, 12);
    expect(custom.peakSunHours, SizingConfig.defaults.peakSunHours);
    expect(SizingConfig.fromMap(null).panelWattage, 585);
  });
}
