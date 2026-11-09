import 'package:cloud_firestore/cloud_firestore.dart';
import '../../home/data/home_repository.dart';
import '../../home/domain/home_product.dart';
import '../domain/solar_sizing.dart';

/// A ready-made system an admin built from real products (packages/{id},
/// written by admin-savePackage).
class SolarPackage {
  const SolarPackage({
    required this.id,
    required this.names,
    required this.systemType,
    required this.sizeKw,
    required this.batteryKwh,
    required this.items,
  });

  factory SolarPackage.fromFirestore(String id, Map<String, dynamic> d) => SolarPackage(
        id: id,
        names: Map<String, String>.from((d['name'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? const {}),
        systemType: switch (d['systemType']) {
          'hybrid' => SystemType.hybrid,
          'offGrid' => SystemType.offGrid,
          _ => SystemType.onGrid,
        },
        sizeKw: (d['sizeKw'] as num?)?.toDouble() ?? 0,
        batteryKwh: (d['batteryKwh'] as num?)?.toDouble(),
        items: [
          for (final it in (d['items'] as List? ?? const []))
            if (it is Map && it['productId'] is String && it['qty'] is num) (productId: it['productId'] as String, qty: (it['qty'] as num).toInt()),
        ],
      );

  final String id;
  final Map<String, String> names;
  final SystemType systemType;
  final double sizeKw;
  final double? batteryKwh;
  final List<({String productId, int qty})> items;

  String nameFor(String languageCode) {
    final key = languageCode == 'ckb' ? 'ku' : languageCode;
    return names[key] ?? names['en'] ?? names.values.firstOrNull ?? '';
  }
}

/// A package with its products resolved, ready to show and add to the cart.
class PackageOffer {
  const PackageOffer({required this.package, required this.lines});

  final SolarPackage package;
  final List<({HomeProduct product, int qty})> lines;

  bool get inStock => lines.every((l) => l.product.inStock);

  Map<String, double> get totals {
    final t = <String, double>{};
    for (final l in lines) {
      t[l.product.currency] = (t[l.product.currency] ?? 0) + l.product.priceValue * l.qty;
    }
    return t;
  }
}

/// The packages that fit [type], closest in size to [inverterKw] first
/// (on a tie, the bigger one — undersizing is the worse mistake).
List<PackageOffer> recommendPackages(List<PackageOffer> offers, SystemType type, double inverterKw, {int max = 3}) {
  final fit = offers.where((o) => o.package.systemType == type).toList()
    ..sort((a, b) {
      final da = (a.package.sizeKw - inverterKw).abs();
      final db = (b.package.sizeKw - inverterKw).abs();
      return da != db ? da.compareTo(db) : b.package.sizeKw.compareTo(a.package.sizeKw);
    });
  return fit.take(max).toList();
}

class CalculatorRepository {
  CalculatorRepository({FirebaseFirestore? firestore, HomeRepository? products})
      : _db = firestore ?? FirebaseFirestore.instance,
        _products = products ?? HomeRepository(firestore: firestore);

  final FirebaseFirestore _db;
  final HomeRepository _products;

  Future<SizingConfig> fetchConfig() async {
    final doc = await _db.collection('config').doc('calculator').get();
    return SizingConfig.fromMap(doc.data());
  }

  /// Active packages whose products are all still on sale (a package with
  /// a removed product, or one from a seller no longer approved, is left
  /// out rather than shown incomplete).
  Future<List<PackageOffer>> fetchOffers() async {
    final snap = await _db.collection('packages').where('active', isEqualTo: true).limit(100).get();
    final packages = snap.docs.map((d) => SolarPackage.fromFirestore(d.id, d.data())).where((p) => p.items.isNotEmpty).toList();
    final ids = {for (final p in packages) ...p.items.map((i) => i.productId)}.toList();
    final byId = {for (final p in await _products.fetchProductsByIds(ids)) p.id: p};
    return [
      for (final p in packages)
        if (p.items.every((i) => byId.containsKey(i.productId)))
          PackageOffer(package: p, lines: [for (final i in p.items) (product: byId[i.productId]!, qty: i.qty)]),
    ];
  }
}
