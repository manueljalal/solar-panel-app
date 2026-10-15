import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/learn_item.dart';

/// Reads Learn content live from Firestore. Errors propagate so the UI can
/// show a real error state; an empty collection is an empty list — there is
/// no built-in fallback content.
class LearnRepository {
  LearnRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // The admin tool caps items at 50; the limit here is a second guard so the
  // list never grows unbounded. Only metadata is read — the video bytes are
  // fetched when an item is opened, not when the list loads.
  static const _max = 50;

  Future<List<LearnItem>> fetchItems() async {
    final snapshot = await _db.collection('learnItems').orderBy('createdAt', descending: true).limit(_max).get();
    return snapshot.docs
        .map((d) => LearnItem.fromFirestore(d.id, d.data()))
        .where((i) => i.videoUrl.startsWith('https://'))
        .toList();
  }
}
