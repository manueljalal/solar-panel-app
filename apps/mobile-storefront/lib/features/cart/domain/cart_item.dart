import '../../home/domain/home_product.dart';

/// One line in the cart: a product plus how many the shopper wants.
class CartItem {
  const CartItem({required this.product, required this.quantity});

  final HomeProduct product;
  final int quantity;

  /// Numeric unit price from the product doc. Falls back to parsing the
  /// display string only for products built without one (test fixtures).
  double get unitPrice {
    if (product.priceValue > 0) return product.priceValue;
    final digits = product.price.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(digits) ?? 0;
  }

  String get currency => product.currency;

  double get lineTotal => unitPrice * quantity;

  CartItem copyWith({int? quantity}) => CartItem(product: product, quantity: quantity ?? this.quantity);
}
