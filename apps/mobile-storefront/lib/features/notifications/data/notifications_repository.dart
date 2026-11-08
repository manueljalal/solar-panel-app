import 'package:cloud_firestore/cloud_firestore.dart';

/// One in-app notification. The backend stores a type plus parameters
/// (backend/functions/src/shared/notify.ts), and the app words it in the
/// reader's language.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.params,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(String id, Map<String, dynamic> d) => AppNotification(
        id: id,
        type: d['type'] as String? ?? '',
        params: Map<String, dynamic>.from(d['params'] as Map? ?? const {}),
        read: d['read'] == true,
        createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  final String id;
  final String type;
  final Map<String, dynamic> params;
  final bool read;
  final DateTime createdAt;

  String param(String key) => params[key]?.toString() ?? '';
}

/// The signed-in user's notifications/{id} docs. Rules let the owner read
/// them and set `read` — nothing else.
class NotificationsRepository {
  NotificationsRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const _limit = 50;

  Query<Map<String, dynamic>> _mine(String uid) => _db.collection('notifications').where('uid', isEqualTo: uid);

  Stream<List<AppNotification>> watch(String uid) => _mine(uid)
      .orderBy('createdAt', descending: true)
      .limit(_limit)
      .snapshots()
      .map((s) => s.docs.map((d) => AppNotification.fromFirestore(d.id, d.data())).toList());

  Stream<int> watchUnreadCount(String uid) =>
      _mine(uid).where('read', isEqualTo: false).limit(_limit).snapshots().map((s) => s.size);

  Future<void> markRead(Iterable<AppNotification> items) async {
    final unread = items.where((n) => !n.read).toList();
    if (unread.isEmpty) return;
    final batch = _db.batch();
    for (final n in unread) {
      batch.update(_db.collection('notifications').doc(n.id), {'read': true});
    }
    await batch.commit();
  }
}
