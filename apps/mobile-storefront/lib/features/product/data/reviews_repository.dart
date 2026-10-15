import 'package:cloud_firestore/cloud_firestore.dart';

class ProductReview {
  const ProductReview({required this.rating, required this.comment, required this.reviewerName, this.createdAt});

  final int rating;
  final String comment;
  final String reviewerName;
  final DateTime? createdAt;
}

/// Verified-purchase reviews (written by storefront-submitReview, publicly
/// readable). Uses the (productId, createdAt desc) index.
class ReviewsRepository {
  ReviewsRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<List<ProductReview>> latestFor(String productId, {int limit = 10}) async {
    final snap = await _db
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      final at = data['createdAt'];
      return ProductReview(
        rating: (data['rating'] as num?)?.toInt() ?? 0,
        comment: data['comment'] as String? ?? '',
        reviewerName: data['reviewerName'] as String? ?? '',
        createdAt: at is Timestamp ? at.toDate() : null,
      );
    }).toList();
  }
}
