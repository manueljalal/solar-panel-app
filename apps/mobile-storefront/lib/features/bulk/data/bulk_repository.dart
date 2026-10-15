import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import '../domain/bulk_models.dart';

/// Bulk marketplace API — every call goes through the `bulk-*` Cloud
/// Functions, which only answer approved vendors. There is deliberately no
/// direct Firestore access: bulk prices must never be readable by shoppers.
class BulkRepository {
  BulkRepository({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<List<BulkListing>> listListings({
    BulkCountry? country,
    bool mine = false,
  }) async {
    final rows = await _list('bulk-listListings', 'listings', country, mine);
    return [for (final r in rows) BulkListing.fromJson(r)];
  }

  Future<List<BulkRequest>> listRequests({
    BulkCountry? country,
    bool mine = false,
  }) async {
    final rows = await _list('bulk-listRequests', 'requests', country, mine);
    return [for (final r in rows) BulkRequest.fromJson(r)];
  }

  Future<List<Map<String, dynamic>>> _list(
    String name,
    String key,
    BulkCountry? country,
    bool mine,
  ) async {
    final result = await _functions.httpsCallable(name).call({
      if (country != null) 'country': country.code,
      if (mine) 'mine': true,
    });
    final rows = (result.data as Map)[key] as List? ?? const [];
    return [for (final r in rows) Map<String, dynamic>.from(r as Map)];
  }

  /// Uploads a post photo through vendor-uploadImage (the same endpoint and
  /// per-vendor folder product images use) and returns its URL.
  Future<String> uploadImage(Uint8List bytes) async {
    final result = await _functions.httpsCallable('vendor-uploadImage').call({
      'purpose': 'product',
      'data': base64Encode(bytes),
    });
    return (result.data as Map)['url'] as String;
  }

  Future<void> createListing({
    required Map<String, String> title,
    required Map<String, String> description,
    String? imageUrl,
    required String unit,
    required List<BulkTier> tiers,
    String? categoryId,
  }) async {
    await _functions.httpsCallable('bulk-createListing').call({
      'title': title,
      'description': description,
      'unit': unit,
      'tiers': [for (final t in tiers) t.toJson()],
      'categoryId': ?categoryId,
      'imageUrl': ?imageUrl,
    });
  }

  Future<void> createRequest({
    required Map<String, String> title,
    required Map<String, String> description,
    String? imageUrl,
    required String unit,
    required int quantity,
    double? targetPriceUsd,
    String deliveryCity = '',
    String? categoryId,
  }) async {
    await _functions.httpsCallable('bulk-createRequest').call({
      'title': title,
      'description': description,
      'unit': unit,
      'quantity': quantity,
      'targetPriceUsd': ?targetPriceUsd,
      'deliveryCity': deliveryCity,
      'categoryId': ?categoryId,
      'imageUrl': ?imageUrl,
    });
  }

  Future<void> closePost({required bool isListing, required String id}) async {
    await _functions.httpsCallable('bulk-closePost').call({
      'kind': isListing ? 'listing' : 'request',
      'id': id,
    });
  }
}
