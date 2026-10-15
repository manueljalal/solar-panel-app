import '../../home/domain/home_product.dart';

/// One line in the cart: a product plus how many the shopper wants.
class CartItem {
  const CartItem({required this.product, required this.quantity});

  final HomeProduct product;
  final int quantity;

  /// The numeric price from Firestore. Falls back to parsing the display
  /// string only for hand-built products that have no numeric price.
  double get unitPrice {
    if (product.priceValue > 0) return product.priceValue;
    final digits = product.price.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(digits) ?? 0;
  }

  double get lineTotal => unitPrice * quantity;

  String get currency => product.currency;

  /// Same identity the controller uses: Firestore id, or title for
  /// id-less fixtures.
  String get key => product.id.isNotEmpty ? product.id : product.title;

  CartItem copyWith({int? quantity}) => CartItem(product: product, quantity: quantity ?? this.quantity);

  /// Just enough to redraw the cart after a restart. Prices shown here may
  /// be stale; checkout re-prices everything server-side.
  Map<String, Object?> toJson() => {
    'id': product.id,
    'vendorId': product.vendorId,
    'title': product.title,
    'titles': product.titles,
    'vendor': product.vendor,
    'imageUrl': product.imageUrl,
    'spec': product.spec,
    'brand': product.brand,
    'price': product.price,
    'priceValue': product.priceValue,
    'currency': product.currency,
    'quantity': quantity,
  };

  static CartItem? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final quantity = raw['quantity'];
    if (quantity is! int || quantity <= 0) return null;
    final titles = raw['titles'];
    return CartItem(
      quantity: quantity,
      product: HomeProduct(
        id: raw['id'] as String? ?? '',
        vendorId: raw['vendorId'] as String? ?? '',
        title: raw['title'] as String? ?? '',
        titles: titles is Map ? {for (final e in titles.entries) '${e.key}': '${e.value}'} : const {},
        vendor: raw['vendor'] as String? ?? '',
        imageUrl: raw['imageUrl'] as String? ?? '',
        spec: raw['spec'] as String? ?? '',
        brand: raw['brand'] as String? ?? '',
        price: raw['price'] as String? ?? '',
        priceValue: (raw['priceValue'] as num?)?.toDouble() ?? 0,
        currency: raw['currency'] as String? ?? 'USD',
        rating: 0,
        sold: 0,
      ),
    );
  }
}
