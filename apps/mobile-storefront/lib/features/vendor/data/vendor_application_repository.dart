import 'package:cloud_functions/cloud_functions.dart';
import '../../../shared/location/picked_location.dart';

enum ApplicationStatus { pending, approved, rejected }

class MyApplication {
  const MyApplication({required this.status, required this.businessName});

  final ApplicationStatus status;
  final String businessName;
}

/// Submits a vendor application via the vendor-submitApplication Cloud
/// Function — not a direct Firestore write. The uid is taken server-side
/// from the verified auth token, and firestore.rules refuses client
/// writes to `vendorApplications` entirely (see that collection's rule
/// comment) so this callable is the only path that can create one.
///
/// The applicant's phone is deliberately NOT a parameter: the server reads
/// it from the WhatsApp-verified account, since that number is the vendor's
/// login credential.
class VendorApplicationRepository {
  VendorApplicationRepository({FirebaseFunctions? functions}) : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<void> submit({
    required String businessName,
    required String city,
    required String address,
    required String email,
    required String note,
    required PickedLocation location,
  }) async {
    final callable = _functions.httpsCallable('vendor-submitApplication');
    await callable.call({
      'businessName': businessName,
      'city': city,
      'address': address,
      'email': email,
      'note': note,
      'location': location.toJson(),
    });
  }

  /// The caller's most recent application, or null if they never applied.
  Future<MyApplication?> getMine() async {
    final result = await _functions.httpsCallable('vendor-getMyApplication').call();
    final application = (result.data as Map)['application'] as Map?;
    if (application == null) return null;
    return MyApplication(
      status: ApplicationStatus.values.firstWhere(
        (s) => s.name == application['status'],
        orElse: () => ApplicationStatus.pending,
      ),
      businessName: application['businessName'] as String? ?? '',
    );
  }
}
