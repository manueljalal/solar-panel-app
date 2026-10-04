import 'package:cloud_functions/cloud_functions.dart';
import '../../../shared/location/picked_location.dart';

/// Submits a vendor application via the vendor-submitApplication Cloud
/// Function — not a direct Firestore write. The uid is taken server-side
/// from the verified auth token, and firestore.rules refuses client
/// writes to `vendorApplications` entirely (see that collection's rule
/// comment) so this callable is the only path that can create one.
class VendorApplicationRepository {
  VendorApplicationRepository({FirebaseFunctions? functions}) : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<void> submit({
    required String businessName,
    required String city,
    required String address,
    required String phone,
    required String email,
    required String note,
    required PickedLocation location,
  }) async {
    final callable = _functions.httpsCallable('vendor-submitApplication');
    await callable.call({
      'businessName': businessName,
      'city': city,
      'address': address,
      'phone': phone,
      'email': email,
      'note': note,
      'location': location.toJson(),
    });
  }
}
