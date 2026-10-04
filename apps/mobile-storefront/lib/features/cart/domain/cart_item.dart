import '../../home/domain/home_product.dart';

/// One line in the cart: a product plus how many the shopper wants.
class CartItem {
  const CartItem({required this.product, required this.quantity});

  final HomeProduct product;
  final int quantity;

  /// Parses HomeProduct.price ("$189", "$1,240") back into a number for
  /// totals math. Fragile by construction — HomeProduct stores price as a
  /// display string because that's what the product list needs; once
  /// products come with a real numeric price field end-to-end (the
  /// Firestore doc already has one — see home_repository.dart), thread
  /// that through instead of re-parsing text.
  double get unitPrice {
    final digits = product.price.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(digits) ?? 0;
  }

  double get lineTotal => unitPrice * quantity;

  CartItem copyWith({int? quantity}) => CartItem(product: product, quantity: quantity ?? this.quantity);
}
