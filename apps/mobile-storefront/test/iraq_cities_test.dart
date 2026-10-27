import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/shared/iraq_cities.dart';

void main() {
  test('city spellings in English, Arabic and Kurdish resolve to one city', () {
    for (final raw in ['Erbil', 'ERBIL', ' erbil ', 'Hawler', 'Arbil', 'أربيل', 'اربيل', 'هەولێر']) {
      expect(matchIraqCity(raw)?.id, 'Erbil', reason: raw);
    }
    expect(matchIraqCity('Sulaimani')?.id, 'Sulaymaniyah');
    expect(matchIraqCity('السليمانية')?.id, 'Sulaymaniyah');
    expect(matchIraqCity('البصرة')?.id, 'Basra');
  });

  test('unknown or empty cities do not match', () {
    expect(matchIraqCity('df'), isNull);
    expect(matchIraqCity(''), isNull);
    expect(matchIraqCity(null), isNull);
  });
}
