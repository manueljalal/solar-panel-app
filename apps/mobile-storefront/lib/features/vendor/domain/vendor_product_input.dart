/// Input shape for creating/editing a vendor's own product — mirrors
/// CreateProductInput in backend/functions/src/vendor/create_product.ts.
/// Kept separate from HomeProduct (the read-side display model used by
/// the storefront) since the two serve different purposes: this is what
/// a vendor submits, HomeProduct is what a shopper sees.
class VendorProductInput {
  const VendorProductInput({
    required this.category,
    required this.brand,
    required this.name,
    required this.spec,
    required this.price,
    this.wattage,
    this.currency = 'USD',
    this.imageUrl = '',
    this.description,
    this.warranty,
  });

  final String category; // residential | commercial | battery | inverter
  final String brand;
  final String name;
  final String spec;
  final double price;
  final int? wattage;
  final String currency;
  final String imageUrl;
  final String? description;
  final String? warranty;

  Map<String, dynamic> toJson() => {
        'category': category,
        'brand': brand,
        'name': name,
        'spec': spec,
        'price': price,
        if (wattage != null) 'wattage': wattage,
        'currency': currency,
        'imageUrl': imageUrl,
        if (description != null) 'description': description,
        if (warranty != null) 'warranty': warranty,
      };
}

const vendorProductCategories = ['residential', 'commercial', 'battery', 'inverter'];
