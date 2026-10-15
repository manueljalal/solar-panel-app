/// One Learn entry — a document in the Firestore `learnItems` collection,
/// managed by the super admin: a title and description in Kurdish, Arabic
/// and English, plus an MP4 video.
class LearnItem {
  const LearnItem({required this.id, required this.titles, required this.descriptions, required this.videoUrl, this.thumbnailUrl, this.durationSec});

  factory LearnItem.fromFirestore(String id, Map<String, dynamic> data) {
    return LearnItem(
      id: id,
      titles: _i18n(data['title']),
      descriptions: _i18n(data['description']),
      videoUrl: data['videoUrl'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String?,
      durationSec: (data['durationSec'] as num?)?.toInt(),
    );
  }

  final String id;
  final Map<String, String> titles;
  final Map<String, String> descriptions;
  final String videoUrl;
  final String? thumbnailUrl;
  final int? durationSec;

  /// "4:32" / "1:02:09" — null when the length isn't known.
  String? get durationLabel {
    final total = durationSec;
    if (total == null || total <= 0) return null;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final sec = (total % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$sec' : '$m:$sec';
  }

  static Map<String, String> _i18n(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final k in const ['ku', 'ar', 'en'])
        if (raw[k] is String) k: raw[k] as String,
    };
  }

  // The app's Sorani Kurdish locale is 'ckb'; data is stored under 'ku'.
  static String _pick(Map<String, String> m, String languageCode) {
    final v = m[languageCode == 'ckb' ? 'ku' : languageCode];
    return (v == null || v.isEmpty) ? (m['en'] ?? '') : v;
  }

  String titleFor(String languageCode) => _pick(titles, languageCode);
  String descriptionFor(String languageCode) => _pick(descriptions, languageCode);
}
