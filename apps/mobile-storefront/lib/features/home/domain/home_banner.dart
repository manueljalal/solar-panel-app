import 'package:flutter/painting.dart' show Color;

/// A slide in the home screen's promo carousel — a document in the
/// Firestore `banners` collection, managed by the super admin (max 5).
class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.imageUrl,
    required this.titles,
    this.overlay,
  });

  factory HomeBanner.fromFirestore(String id, Map<String, dynamic> data) {
    final raw = data['title'];
    return HomeBanner(
      id: id,
      imageUrl: data['imageUrl'] as String? ?? '',
      overlay: _parseHex(data['overlayColor']),
      titles: {
        if (raw is Map)
          for (final k in const ['ku', 'ar', 'en'])
            if (raw[k] is String) k: raw[k] as String,
      },
    );
  }

  final String id;

  /// Admin-chosen shade behind the headline; null = no overlay.
  final Color? overlay;
  final String imageUrl;

  /// Optional headline per language ('ku', 'ar', 'en'); empty = image only.
  final Map<String, String> titles;

  /// The app's Sorani Kurdish locale is 'ckb'; data is stored under 'ku'.
  String? titleFor(String languageCode) {
    final v = titles[languageCode == 'ckb' ? 'ku' : languageCode];
    return (v == null || v.isEmpty) ? titles['en'] : v;
  }

  static Color? _parseHex(Object? raw) {
    if (raw is! String || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(raw)) {
      return null;
    }
    return Color(0xFF000000 | int.parse(raw.substring(1), radix: 16));
  }
}
