import 'learn_item.dart';

/// A Learn course (Firestore `courses`): a titled series of episodes
/// (learnItems with this courseId), free or paid.
class Course {
  const Course({
    required this.id,
    required this.titles,
    required this.descriptions,
    required this.coverUrl,
    required this.isPaid,
    required this.priceLabel,
    required this.order,
    this.episodes = const [],
  });

  factory Course.fromFirestore(String id, Map<String, dynamic> data) => Course(
        id: id,
        titles: _i18n(data['title']),
        descriptions: _i18n(data['description']),
        coverUrl: data['coverUrl'] as String? ?? '',
        isPaid: data['access'] == 'paid',
        priceLabel: data['priceLabel'] as String? ?? '',
        order: (data['order'] as num?)?.toInt() ?? 100,
      );

  final String id;
  final Map<String, String> titles;
  final Map<String, String> descriptions;
  final String coverUrl;

  /// Paid courses are shown as Premium: episode 1 is a free preview, the
  /// rest are locked until paid access exists.
  final bool isPaid;
  final String priceLabel;
  final int order;

  /// Sorted by episode number.
  final List<LearnItem> episodes;

  Course withEpisodes(List<LearnItem> list) => Course(
        id: id,
        titles: titles,
        descriptions: descriptions,
        coverUrl: coverUrl,
        isPaid: isPaid,
        priceLabel: priceLabel,
        order: order,
        episodes: list,
      );

  /// Whether this episode can be watched now.
  bool canWatch(LearnItem episode) => !isPaid || episodes.indexOf(episode) == 0;

  int get totalSeconds => episodes.fold(0, (s, e) => s + (e.durationSec ?? 0));

  String titleFor(String languageCode) => _pick(titles, languageCode);
  String descriptionFor(String languageCode) => _pick(descriptions, languageCode);

  static Map<String, String> _i18n(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final k in const ['ku', 'ar', 'en'])
        if (raw[k] is String) k: raw[k] as String,
    };
  }

  static String _pick(Map<String, String> m, String languageCode) {
    final v = m[languageCode == 'ckb' ? 'ku' : languageCode];
    return (v == null || v.isEmpty) ? (m['en'] ?? '') : v;
  }
}
