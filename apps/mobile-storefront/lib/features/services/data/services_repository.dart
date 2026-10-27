import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../../../shared/location/picked_location.dart';
import '../domain/service_request.dart';

class ServicesRepository {
  ServicesRepository({FirebaseFunctions? functions, FirebaseFirestore? firestore})
      : _fn = functions,
        _fs = firestore;

  final FirebaseFunctions? _fn;
  final FirebaseFirestore? _fs;
  FirebaseFunctions get _functions => _fn ?? FirebaseFunctions.instance;
  FirebaseFirestore get _db => _fs ?? FirebaseFirestore.instance;

  /// Bumped after a request is created or cancelled so the Services tab reloads.
  static final changes = ValueNotifier<int>(0);

  Future<SupportInfo> support() async {
    final d = (await _db.collection('config').doc('support').get()).data() ?? const {};
    return SupportInfo(
      phone: d['phone'] as String? ?? '',
      whatsapp: d['whatsapp'] as String? ?? '',
      hours: d['hours'] as String? ?? '',
      email: d['email'] as String? ?? '',
    );
  }

  Future<void> request({
    required ServiceType type,
    required String address,
    required String city,
    required PickedLocation location,
    DateTime? preferredDate,
    double? panelCount,
    double? systemSizeKw,
    String note = '',
  }) async {
    await _functions.httpsCallable('storefront-requestService').call({
      'type': type.name,
      'address': address,
      'city': city,
      'location': location.toJson(),
      'preferredDate': ?preferredDate?.millisecondsSinceEpoch,
      'panelCount': ?panelCount,
      'systemSizeKw': ?systemSizeKw,
      'note': note,
    });
    changes.value++;
  }

  Future<List<ServiceRequest>> listMine() async {
    final rows = ((await _functions.httpsCallable('storefront-listMyServiceRequests').call()).data as Map)['requests']
            as List? ??
        const [];
    return [for (final r in rows) ServiceRequest.fromJson(Map<String, dynamic>.from(r as Map))];
  }

  Future<void> cancel(String id) async {
    await _functions.httpsCallable('storefront-cancelMyServiceRequest').call({'id': id});
    changes.value++;
  }
}
