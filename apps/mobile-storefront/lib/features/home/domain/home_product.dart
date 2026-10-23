/// A listing shown in the home screen's "Best sellers" section and, when
/// tapped, on the product detail screen. One model serves both — a list
/// row shows a subset of these fields, the detail screen shows all of them.
class HomeProduct {
  const HomeProduct({
    this.id = '',
    this.vendorId = '',
    this.priceValue,
    this.currency = 'USD',
    required this.imageUrl,
    required this.spec,
    required this.brand,
    required this.title,
    required this.vendor,
    required this.price,
    required this.rating,
    required this.sold,
    this.warranty,
    this.description,
    this.inStock = true,
    this.titles = const {},
    this.descriptions = const {},
    this.warranties = const {},
  });

  /// Firestore `products` doc id — what checkout sends to placeOrder.
  /// Empty only on hand-built test fixtures.
  final String id;
  final String vendorId;

  /// The real numeric price behind the [price] display string. Null on
  /// fixtures that only set [price]; see CartItem.unitPrice.
  final double? priceValue;
  final String currency;

  final String imageUrl;
  final String spec;
  final String brand;
  final String title;
  final String vendor;
  final String price;
  final double rating;
  final int sold;

  /// Detail-screen-only fields — null on rows that don't need them yet,
  /// but every seeded product below fills them in.
  final String? warranty;
  final String? description;
  final bool inStock;

  /// Per-language text keyed by language code ('en', 'ar', 'ku') — see the
  /// vendor portal's trilingual product form. Empty on legacy products.
  final Map<String, String> titles;
  final Map<String, String> descriptions;
  final Map<String, String> warranties;

  // The app's Sorani Kurdish locale is 'ckb'; data is stored under 'ku'.
  static String _key(String languageCode) =>
      languageCode == 'ckb' ? 'ku' : languageCode;

  String titleFor(String languageCode) => _pick(titles, languageCode) ?? title;
  String? descriptionFor(String languageCode) =>
      _pick(descriptions, languageCode) ?? description;
  String? warrantyFor(String languageCode) =>
      _pick(warranties, languageCode) ?? warranty;

  static String? _pick(Map<String, String> m, String languageCode) {
    final v = m[_key(languageCode)];
    return (v == null || v.isEmpty) ? null : v;
  }

  static Map<String, String> _i18n(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final k in const ['ku', 'ar', 'en'])
        if (raw[k] is String) k: raw[k] as String,
    };
  }

  /// Builds a HomeProduct from a Firestore `products` document. Firestore
  /// stores `price` as a number and the seller as `vendorId` (a reference,
  /// not a display name) — [vendorName] is resolved by the repository via
  /// a join against `vendors` before this is called.
  factory HomeProduct.fromFirestore(
    String id,
    Map<String, dynamic> data, {
    required String vendorName,
  }) {
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final currency = data['currency'] as String? ?? 'USD';
    final symbol = currency == 'USD' ? '\$' : '$currency ';
    return HomeProduct(
      id: id,
      vendorId: data['vendorId'] as String? ?? '',
      priceValue: price,
      currency: currency,
      imageUrl: data['imageUrl'] as String? ?? '',
      spec: data['spec'] as String? ?? '',
      brand: data['brand'] as String? ?? '',
      title: data['name'] as String? ?? 'Untitled product',
      vendor: vendorName,
      price:
          '$symbol${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}',
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      sold: (data['sold'] as num?)?.toInt() ?? 0,
      warranty: data['warranty'] as String?,
      description: data['description'] as String?,
      inStock: data['inStock'] as bool? ?? true,
      titles: _i18n(data['nameI18n']),
      descriptions: _i18n(data['descriptionI18n']),
      warranties: _i18n(data['warrantyI18n']),
    );
  }

  /// Local cart persistence (see CartStorage) — the subset of fields the
  /// cart and checkout screens show. Prices are re-read server-side at
  /// checkout, so a stale saved copy can never change what's charged.
  Map<String, Object?> toJson() => {
    'id': id,
    'vendorId': vendorId,
    'priceValue': priceValue,
    'currency': currency,
    'imageUrl': imageUrl,
    'spec': spec,
    'brand': brand,
    'title': title,
    'vendor': vendor,
    'price': price,
    'rating': rating,
    'sold': sold,
    'inStock': inStock,
    'titles': titles,
  };

  factory HomeProduct.fromJson(Map<String, Object?> json) => HomeProduct(
    id: json['id'] as String? ?? '',
    vendorId: json['vendorId'] as String? ?? '',
    priceValue: (json['priceValue'] as num?)?.toDouble(),
    currency: json['currency'] as String? ?? 'USD',
    imageUrl: json['imageUrl'] as String? ?? '',
    spec: json['spec'] as String? ?? '',
    brand: json['brand'] as String? ?? '',
    title: json['title'] as String? ?? '',
    vendor: json['vendor'] as String? ?? '',
    price: json['price'] as String? ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    sold: (json['sold'] as num?)?.toInt() ?? 0,
    inStock: json['inStock'] as bool? ?? true,
    titles: _i18n(json['titles']),
  );
}
