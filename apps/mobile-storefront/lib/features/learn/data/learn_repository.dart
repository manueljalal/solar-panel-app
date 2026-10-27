import 'package:cloud_firestore/cloud_firestore.dart';
import '../../home/domain/home_banner.dart';
import '../domain/course.dart';
import '../domain/learn_item.dart';

/// Everything the Learn tab shows, read live from Firestore.
class LearnContent {
  const LearnContent({required this.banners, required this.courses, required this.standalone});

  final List<HomeBanner> banners;

  /// Courses that have at least one episode, in admin order.
  final List<Course> courses;

  /// Videos that aren't part of a course.
  final List<LearnItem> standalone;

  bool get isEmpty => banners.isEmpty && courses.isEmpty && standalone.isEmpty;
}

/// Reads Learn content live from Firestore. Errors propagate so the UI can
/// show a real error state; there is no built-in fallback content.
class LearnRepository {
  LearnRepository({FirebaseFirestore? firestore}) : _injected = firestore;

  final FirebaseFirestore? _injected;

  // Resolved on first read, not in the constructor: if Firebase isn't
  // available the failure lands in the Future (shown as the screen's error
  // state) instead of throwing while the screen builds.
  FirebaseFirestore get _db => _injected ?? FirebaseFirestore.instance;

  // The admin tool caps items at 300; the limit here is a second guard. Only
  // metadata is read — video bytes load when an episode is opened.
  static const _max = 300;

  Future<List<LearnItem>> fetchItems() async {
    final snapshot = await _db.collection('learnItems').orderBy('createdAt', descending: true).limit(_max).get();
    return snapshot.docs
        .map((d) => LearnItem.fromFirestore(d.id, d.data()))
        .where((i) => i.videoUrl.startsWith('https://'))
        .toList();
  }

  Future<LearnContent> fetchAll() async {
    // Resolve Firestore once, before starting any request: if it throws,
    // this Future fails cleanly instead of leaving a sibling request's
    // error unhandled.
    final db = _db;
    final results = await Future.wait([
      fetchItems(),
      db.collection('courses').limit(100).get(),
      db.collection('banners').limit(20).get(),
    ]);
    final items = results[0] as List<LearnItem>;
    final courseDocs = (results[1] as QuerySnapshot<Map<String, dynamic>>).docs;
    final bannerDocs = (results[2] as QuerySnapshot<Map<String, dynamic>>).docs;

    final courseIds = {for (final d in courseDocs) d.id};
    final byCourse = <String, List<LearnItem>>{};
    final standalone = <LearnItem>[];
    for (final i in items) {
      if (i.courseId != null && courseIds.contains(i.courseId)) {
        byCourse.putIfAbsent(i.courseId!, () => []).add(i);
      } else {
        standalone.add(i);
      }
    }
    final courses = [
      for (final d in courseDocs)
        if (byCourse[d.id]?.isNotEmpty ?? false)
          Course.fromFirestore(d.id, d.data()).withEpisodes(
            byCourse[d.id]!..sort((a, b) => (a.episodeNumber ?? 999).compareTo(b.episodeNumber ?? 999)),
          ),
    ]..sort((a, b) => a.order.compareTo(b.order));

    final banners = bannerDocs
        .map((d) => HomeBanner.fromFirestore(d.id, d.data()))
        .where((b) => b.imageUrl.isNotEmpty && b.placement == 'learn')
        .toList();

    return LearnContent(banners: banners, courses: courses, standalone: standalone);
  }
}
