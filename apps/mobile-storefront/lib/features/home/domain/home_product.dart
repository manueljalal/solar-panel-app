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

// Fallback content only — used by widget tests (no Firestore in the test
// environment) and as an offline/error fallback in ProductRow/home screen.
// The backend exists now: real reads go through HomeRepository against the
// `products` collection, seeded via scripts/seed-firestore.mjs with this
// exact data (photos are the same verified-working Unsplash URLs).
const homeProducts = [
  HomeProduct(
    imageUrl: 'https://images.unsplash.com/photo-1509391366360-2e959784a276?w=400&q=80',
    spec: '450W',
    brand: 'JinkoSolar',
    title: 'Tiger Neo Mono Panel',
    vendor: 'SunBridge Energy',
    price: '\$189',
    rating: 4.9,
    sold: 312,
    warranty: '25-year power output',
    description:
        'High-efficiency N-type monocrystalline panel with a low temperature '
        'coefficient, built for rooftop residential arrays. Ships with '
        'mounting hardware compatible with most rail systems.',
  ),
  HomeProduct(
    imageUrl: 'https://images.unsplash.com/photo-1624397640148-949b1732bb0a?w=400&q=80',
    spec: '5kWh',
    brand: 'Huawei',
    title: 'LUNA2000 Battery Unit',
    vendor: 'Helios Power Co.',
    price: '\$1,240',
    rating: 4.8,
    sold: 87,
    warranty: '10-year manufacturer',
    description:
        'Modular lithium home battery designed to pair with a residential '
        'inverter for backup power and time-of-use savings. Wall-mounted, '
        'stackable up to 3 units for extra capacity.',
  ),
  HomeProduct(
    imageUrl: 'https://images.unsplash.com/photo-1592833159155-c62df1b65634?w=400&q=80',
    spec: '6kW',
    brand: 'Growatt',
    title: 'Hybrid Grid Inverter',
    vendor: 'GreenTech Iraq',
    price: '\$860',
    rating: 4.7,
    sold: 54,
    warranty: '5-year manufacturer',
    description:
        'Hybrid inverter supporting both grid-tied and battery-backed '
        'operation, with built-in Wi-Fi monitoring and support for two MPPT '
        'trackers.',
  ),
  HomeProduct(
    imageUrl: 'https://images.unsplash.com/photo-1613665813446-82a78c468a1d?w=400&q=80',
    spec: '400W',
    brand: 'Canadian Solar',
    title: 'HiKu6 Mono Panel',
    vendor: 'SunBridge Energy',
    price: '\$164',
    rating: 4.6,
    sold: 203,
    warranty: '25-year power output',
    description:
        'Balanced-cost mono panel for larger residential and light-commercial '
        'arrays, with a reinforced frame rated for higher wind and snow loads.',
  ),
];
