import '../../home/domain/home_product.dart';

/// One line in the cart: a product plus how many the shopper wants.
class CartItem {
  const CartItem({required this.product, required this.quantity});

  final HomeProduct product;
  final int quantity;

  /// Products read from Firestore carry their real numeric price
  /// (HomeProduct.priceValue). Only hand-built fixtures lack it, and for
  /// those the display string ("$189", "$1,240") is parsed instead. Either
  /// way this is display-only: placeOrder re-reads every price server-side.
  double get unitPrice {
    final value = product.priceValue;
    if (value != null) return value;
    final digits = product.price.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(digits) ?? 0;
  }

  double get lineTotal => unitPrice * quantity;

  String get currency => product.currency;

  /// Products from Firestore are matched by doc id; fixtures without one
  /// fall back to their title.
  String get key => product.id.isNotEmpty ? product.id : product.title;

  CartItem copyWith({int? quantity}) => CartItem(product: product, quantity: quantity ?? this.quantity);

  Map<String, Object?> toJson() => {'product': product.toJson(), 'quantity': quantity};

  static CartItem? fromJson(Object? json) {
    if (json is! Map) return null;
    final product = json['product'];
    final quantity = json['quantity'];
    if (product is! Map || quantity is! int || quantity <= 0) return null;
    return CartItem(product: HomeProduct.fromJson(product.cast<String, Object?>()), quantity: quantity);
  }
}
