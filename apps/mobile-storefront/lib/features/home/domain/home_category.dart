/// A product category managed by the super admin (Firestore `categories`),
/// with its name in Kurdish, Arabic and English.
class HomeCategory {
  const HomeCategory({
    required this.id,
    required this.names,
    required this.imageUrl,
  });

  factory HomeCategory.fromFirestore(String id, Map<String, dynamic> data) {
    final raw = data['name'];
    return HomeCategory(
      id: id,
      names: {
        if (raw is Map)
          for (final k in const ['ku', 'ar', 'en'])
            if (raw[k] is String) k: raw[k] as String,
      },
      imageUrl: data['imageUrl'] as String? ?? '',
    );
  }

  /// Document id = slug; products reference it in their `category` field.
  final String id;
  final Map<String, String> names;
  final String imageUrl;

  /// The app's Sorani Kurdish locale is 'ckb'; data is stored under 'ku'.
  String nameFor(String languageCode) {
    final key = languageCode == 'ckb' ? 'ku' : languageCode;
    final v = names[key];
    return (v == null || v.isEmpty) ? (names['en'] ?? id) : v;
  }
}
