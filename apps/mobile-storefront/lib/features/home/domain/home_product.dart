/// A listing shown in the home screen's "Best sellers" section and, when
/// tapped, on the product detail screen. One model serves both — a list
/// row shows a subset of these fields, the detail screen shows all of them.
class HomeProduct {
  const HomeProduct({
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
  });

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

  /// Builds a HomeProduct from a Firestore `products` document. Firestore
  /// stores `price` as a number and the seller as `vendorId` (a reference,
  /// not a display name) — [vendorName] is resolved by the repository via
  /// a join against `vendors` before this is called.
  factory HomeProduct.fromFirestore(Map<String, dynamic> data, {required String vendorName}) {
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final currency = data['currency'] as String? ?? 'USD';
    final symbol = currency == 'USD' ? '\$' : '$currency ';
    return HomeProduct(
      imageUrl: data['imageUrl'] as String? ?? '',
      spec: data['spec'] as String? ?? '',
      brand: data['brand'] as String? ?? '',
      title: data['name'] as String? ?? 'Untitled product',
      vendor: vendorName,
      price: '$symbol${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}',
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      sold: (data['sold'] as num?)?.toInt() ?? 0,
      warranty: data['warranty'] as String?,
      description: data['description'] as String?,
      inStock: data['inStock'] as bool? ?? true,
    );
  }
}
