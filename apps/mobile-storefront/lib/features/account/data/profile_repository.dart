import 'package:cloud_functions/cloud_functions.dart';

class MyProfile {
  const MyProfile({required this.name, required this.username, required this.phone, required this.email});

  final String name;
  final String username;
  final String phone;
  final String email;
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
    );
  }

  /// Only the fields passed are changed. [email] '' clears it.
  Future<void> update({String? name, String? username, String? email}) =>
      _functions.httpsCallable('auth-updateMyProfile').call({
        'name': ?name,
        'username': ?username,
        'email': ?email,
      });

  Future<void> changePassword({required String current, required String next}) =>
      _functions.httpsCallable('auth-changePassword').call({'currentPassword': current, 'newPassword': next});

  Future<void> deleteMyAccount() => _functions.httpsCallable('auth-deleteMyAccount').call();
}
