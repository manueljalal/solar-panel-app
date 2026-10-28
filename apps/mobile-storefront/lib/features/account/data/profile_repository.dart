import 'package:cloud_functions/cloud_functions.dart';
import '../../../shared/location/picked_location.dart';

class MyProfile {
  const MyProfile({
    required this.name,
    required this.username,
    required this.phone,
    required this.email,
    this.location,
    this.addressLine = '',
  });

  final String name;
  final String username;
  final String phone;
  final String email;

  /// Saved delivery address: the map pin (set at sign-up, updated whenever
  /// a different address is used) and the street/building details.
  final PickedLocation? location;
  final String addressLine;
}

/// The signed-in user's own profile and account actions (auth-* callables;
/// users/{uid} is not client-readable because it holds the password hash).
class ProfileRepository {
  ProfileRepository({FirebaseFunctions? functions}) : _injected = functions;

  final FirebaseFunctions? _injected;
  FirebaseFunctions get _functions => _injected ?? FirebaseFunctions.instance;

  Future<MyProfile> get() async {
    final d = (await _functions.httpsCallable('auth-getMyProfile').call()).data as Map;
    return MyProfile(
      name: d['name'] as String? ?? '',
      username: d['username'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      email: d['email'] as String? ?? '',
      location: PickedLocation.fromJson(d['location'] == null ? null : Map<String, dynamic>.from(d['location'] as Map)),
      addressLine: d['addressLine'] as String? ?? '',
    );
  }

  /// Only the fields passed are changed. [email] '' clears it.
  Future<void> update({String? name, String? username, String? email, PickedLocation? location, String? addressLine}) =>
      _functions.httpsCallable('auth-updateMyProfile').call({
        'name': ?name,
        'username': ?username,
        'email': ?email,
        'location': ?location?.toJson(),
        'addressLine': ?addressLine,
      });

  Future<void> changePassword({required String current, required String next}) =>
      _functions.httpsCallable('auth-changePassword').call({'currentPassword': current, 'newPassword': next});

  Future<void> deleteMyAccount() => _functions.httpsCallable('auth-deleteMyAccount').call();
}
