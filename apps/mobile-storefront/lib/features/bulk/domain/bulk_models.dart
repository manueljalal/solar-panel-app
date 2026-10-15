/// Home countries a bulk-marketplace company can trade from. The wire value
/// is the ISO code the backend stores (`IQ` / `CN`).
enum BulkCountry {
  iraq('IQ'),
  china('CN');

  const BulkCountry(this.code);
  final String code;

  static BulkCountry fromCode(String? code) =>
      code == 'CN' ? BulkCountry.china : BulkCountry.iraq;
}

class BulkTier {
  const BulkTier({required this.minQty, required this.unitPriceUsd});

  final int minQty;
  final double unitPriceUsd;

  factory BulkTier.fromJson(Map<String, dynamic> json) => BulkTier(
    minQty: (json['minQty'] as num).toInt(),
    unitPriceUsd: (json['unitPriceUsd'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'minQty': minQty,
    'unitPriceUsd': unitPriceUsd,
  };
}

/// Fields shared by both kinds of post — who posted it and how to reach
/// them. Denormalized by the backend so a feed needs no vendor lookups.
abstract class BulkPost {
  const BulkPost({
    required this.id,
    required this.vendorId,
    required this.logoUrl,
    required this.categoryId,
    required this.createdAt,
    required this.businessName,
    required this.country,
    required this.city,
    required this.phone,
    required this.title,
    required this.description,
    required this.titles,
    required this.descriptions,
    required this.imageUrl,
    required this.unit,
    required this.isMine,
    required this.isOpen,
  });

  final String id;

  /// The posting company (`vendors/{vendorId}`), its logo, and the optional
  /// admin-managed category the post is filed under.
  final String vendorId;
  final String logoUrl;
  final String? categoryId;

  /// Milliseconds since epoch (server timestamp); 0 if unknown.
  final int createdAt;
  final String businessName;
  final BulkCountry country;
  final String city;
  final String phone;
  final String title;
  final String description;

  /// Per-language text keyed 'en' / 'ar' / 'ku' — any subset. The
  /// plain [title]/[description] above are the poster's primary version.
  final Map<String, String> titles;
  final Map<String, String> descriptions;

  /// Optional photo; empty when the poster didn't add one.
  final String imageUrl;
  final String unit;
  final bool isMine;
  final bool isOpen;

  /// The title in the viewer's language, falling back to English, then to
  /// whichever language the poster wrote it in. The app's Sorani locale is
  /// 'ckb'; content is stored under 'ku'.
  String titleFor(String languageCode) => _pick(titles, languageCode) ?? title;
  String descriptionFor(String languageCode) =>
      _pick(descriptions, languageCode) ?? description;

  static String? _pick(Map<String, String> m, String languageCode) {
    final key = languageCode == 'ckb' ? 'ku' : languageCode;
    for (final k in [key, 'en']) {
      final v = m[k];
      if (v != null && v.isNotEmpty) return v;
    }
    for (final v in m.values) {
      if (v.isNotEmpty) return v;
    }
    return null;
  }

  static Map<String, String> i18n(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final k in const ['en', 'ar', 'ku'])
        if (raw[k] is String && (raw[k] as String).isNotEmpty)
          k: raw[k] as String,
    };
  }
}

/// A wholesale offer: a product sold in bulk with quantity-tier pricing.
class BulkListing extends BulkPost {
  const BulkListing({
    required super.id,
    required super.vendorId,
    required super.logoUrl,
    required super.categoryId,
    required super.createdAt,
    required super.businessName,
    required super.country,
    required super.city,
    required super.phone,
    required super.title,
    required super.description,
    required super.titles,
    required super.descriptions,
    required super.imageUrl,
    required super.unit,
    required super.isMine,
    required super.isOpen,
    required this.tiers,
  });

  /// Sorted ascending by quantity; the last tier is the best (lowest) price.
  final List<BulkTier> tiers;

  int get moq => tiers.first.minQty;
  double get bestPriceUsd =>
      tiers.map((t) => t.unitPriceUsd).reduce((a, b) => a < b ? a : b);

  factory BulkListing.fromJson(Map<String, dynamic> json) => BulkListing(
    id: json['id'] as String,
    vendorId: json['vendorId'] as String? ?? '',
    logoUrl: json['logoUrl'] as String? ?? '',
    categoryId: json['categoryId'] as String?,
    createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
    businessName: json['businessName'] as String? ?? '',
    country: BulkCountry.fromCode(json['country'] as String?),
    city: json['city'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    titles: BulkPost.i18n(json['titleI18n']),
    descriptions: BulkPost.i18n(json['descriptionI18n']),
    imageUrl: json['imageUrl'] as String? ?? '',
    unit: json['unit'] as String? ?? 'pcs',
    isMine: json['isMine'] == true,
    isOpen: json['status'] == 'active',
    tiers: [
      for (final t in (json['tiers'] as List? ?? const []))
        BulkTier.fromJson(Map<String, dynamic>.from(t as Map)),
    ],
  );
}

/// A buyer request: "I need N units" — answered by vendors contacting the poster.
class BulkRequest extends BulkPost {
  const BulkRequest({
    required super.id,
    required super.vendorId,
    required super.logoUrl,
    required super.categoryId,
    required super.createdAt,
    required super.businessName,
    required super.country,
    required super.city,
    required super.phone,
    required super.title,
    required super.description,
    required super.titles,
    required super.descriptions,
    required super.imageUrl,
    required super.unit,
    required super.isMine,
    required super.isOpen,
    required this.quantity,
    required this.targetPriceUsd,
    required this.deliveryCity,
  });

  final int quantity;
  final double? targetPriceUsd;
  final String deliveryCity;

  factory BulkRequest.fromJson(Map<String, dynamic> json) => BulkRequest(
    id: json['id'] as String,
    vendorId: json['vendorId'] as String? ?? '',
    logoUrl: json['logoUrl'] as String? ?? '',
    categoryId: json['categoryId'] as String?,
    createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
    businessName: json['businessName'] as String? ?? '',
    country: BulkCountry.fromCode(json['country'] as String?),
    city: json['city'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    titles: BulkPost.i18n(json['titleI18n']),
    descriptions: BulkPost.i18n(json['descriptionI18n']),
    imageUrl: json['imageUrl'] as String? ?? '',
    unit: json['unit'] as String? ?? 'pcs',
    isMine: json['isMine'] == true,
    isOpen: json['status'] == 'open',
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    targetPriceUsd: (json['targetPriceUsd'] as num?)?.toDouble(),
    deliveryCity: json['deliveryCity'] as String? ?? '',
  );
}
