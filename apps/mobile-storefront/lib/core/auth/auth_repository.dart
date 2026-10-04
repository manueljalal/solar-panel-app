import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/location/picked_location.dart';
import 'auth_claims.dart';
import 'device_id.dart';

/// Wraps Firebase Auth for the storefront's guest-first model: every
/// visitor gets a real, silent anonymous account on first launch — no
/// login screen, no form — so cart/orders/favorites have a `uid` to
/// attach to from the very first frame.
///
/// The only way to become a *real* (non-anonymous) account is WhatsApp
/// phone OTP (requestPhoneOtp / verifyPhoneOtp) — delivery goes through a
/// Cloud Function + the WhatsApp Business API, not Firebase's own
/// SMS-based Phone Auth. Email/password was removed deliberately: phone
/// verification is the only identity check that actually confirms you
/// reached a real person at that number.
///
/// (not yet built) linking an existing anonymous session via
/// linkWithCredential, so cart/history survives the upgrade.
///
/// Requires the Anonymous sign-in provider to be enabled in the Firebase
/// console (Authentication → Sign-in method → Anonymous) — this is a
/// project-level toggle that can't be set via client code.
class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFunctions? functions})
      : _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

  /// Ensures a signed-in user exists, creating a silent anonymous one if
  /// not. Call once on app start (see main.dart). Returns the resulting
  /// uid, or null if sign-in failed (e.g. Anonymous provider not enabled
  /// yet) — callers should treat that as "browsing works, personalized
  /// features don't yet" rather than a fatal error.
  Future<String?> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing.uid;

    try {
      final credential = await _auth.signInAnonymously();
      return credential.user?.uid;
    } on FirebaseAuthException {
      // Most likely cause: Anonymous provider not enabled in the console
      // yet. Don't crash the app over it — storefront browsing has no
      // auth dependency, only cart/orders/apply do.
      return null;
    }
  }

  /// Reads the caller's role/vendorId custom claims from their current ID
  /// token. Pass [forceRefresh] right after a Cloud Function grants a new
  /// role (e.g. admin-approveVendorApplication) — claims only take effect
  /// on the NEXT token, not the current cached one, so a stale read here
  /// is a real, common bug if this flag is forgotten.
  Future<AuthClaims> getClaims({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return AuthClaims.customer;

    final tokenResult = await user.getIdTokenResult(forceRefresh);
    return AuthClaims.fromToken(tokenResult.claims ?? const {});
  }

  Future<void> signOut() => _auth.signOut();

  /// Step 1 of WhatsApp OTP sign-in — asks the requestPhoneOtp Cloud
  /// Function to generate and send a code. [phone] must be E.164
  /// (+9647501234567), matched by the Function's own validation. Sends
  /// this device's persisted id along so the backend can rate-limit by
  /// device, not just by phone number (see device_id.dart).
  Future<void> requestPhoneOtp(String phone) async {
    final deviceId = await getDeviceId();
    final callable = _functions.httpsCallable('auth-requestPhoneOtp');
    await callable.call({'phone': phone, 'deviceId': deviceId});
  }

  /// Step 2 — verifies the code via the verifyPhoneOtp Cloud Function,
  /// which returns a Firebase custom token on success; this signs the
  /// client in with it. [name] is only used if this is a first-time
  /// verification (new account) — ignored on a repeat sign-in. Throws
  /// FirebaseFunctionsException on a wrong/expired code — callers should
  /// show its .message to the user, it's already human-readable (see
  /// verify_phone_otp.ts's HttpsError messages).
  Future<PhoneSignInResult> verifyPhoneOtp({
    required String phone,
    required String otp,
    String? name,
    PickedLocation? location,
  }) async {
    final deviceId = await getDeviceId();
    final callable = _functions.httpsCallable('auth-verifyPhoneOtp');
    final result = await callable.call({
      'phone': phone,
      'otp': otp,
      'name': name,
      'deviceId': deviceId,
      'location': location?.toJson(),
    });
    final customToken = result.data['customToken'] as String;
    final isNewUser = result.data['isNewUser'] as bool? ?? false;
    final credential = await _auth.signInWithCustomToken(customToken);
    return PhoneSignInResult(user: credential.user!, isNewUser: isNewUser);
  }

  /// Real registration — name + username + password + phone + location,
  /// with [otp] proving phone ownership (call requestPhoneOtp first to
  /// get that code sent). Everything happens in one Cloud Function call
  /// (auth-signUp) so a username+password account can never exist
  /// without the phone having been verified in the same request. Throws
  /// FirebaseFunctionsException with code 'already-exists' if the
  /// username is taken.
  Future<User> signUp({
    required String name,
    required String username,
    required String password,
    required String phone,
    required String otp,
    PickedLocation? location,
  }) async {
    final deviceId = await getDeviceId();
    final callable = _functions.httpsCallable('auth-signUp');
    final result = await callable.call({
      'name': name,
      'username': username,
      'password': password,
      'phone': phone,
      'otp': otp,
      'location': location?.toJson(),
      'deviceId': deviceId,
    });
    final customToken = result.data['customToken'] as String;
    final credential = await _auth.signInWithCustomToken(customToken);
    return credential.user!;
  }

  /// Username + password sign-in. If this device isn't one the account
  /// has seen before, throws [StepUpRequired] (carrying the phone number
  /// on file) instead of returning a token — callers should catch that
  /// specifically and fall back to requestPhoneOtp(e.phone) +
  /// signInOtpStepUp rather than treating it as a generic sign-in
  /// failure. Any other failure (wrong username/password) surfaces as a
  /// plain FirebaseFunctionsException.
  Future<User> signIn({required String username, required String password}) async {
    final deviceId = await getDeviceId();
    final callable = _functions.httpsCallable('auth-signIn');
    try {
      final result = await callable.call({'username': username, 'password': password, 'deviceId': deviceId});
      final customToken = result.data['customToken'] as String;
      final credential = await _auth.signInWithCustomToken(customToken);
      return credential.user!;
    } on FirebaseFunctionsException catch (e) {
      // See sign_in.ts's comment on why the phone number is encoded in
      // the message string rather than HttpsError's `details` param —
      // `details` doesn't reliably survive the callable HTTP transport.
      // TEMP diagnostic — remove once step-up detection is confirmed
      // working across a real device: logs the exact code/message this
      // SDK/platform combination actually delivers, since that's been
      // the repeated point of failure here.
      // ignore: avoid_print
      print('[signIn] FirebaseFunctionsException code=${e.code} message=${e.message} details=${e.details}');
      final message = e.message ?? '';
      if (message.startsWith('step-up-required:')) {
        throw StepUpRequired(message.substring('step-up-required:'.length));
      }
      rethrow;
    }
  }

  /// Completes the step-up signIn demands for an unrecognized device —
  /// call requestPhoneOtp(phone-on-file) first, then this with the code.
  /// On success this device is remembered permanently; future signIns
  /// from it won't need OTP again.
  Future<User> signInOtpStepUp({required String username, required String otp}) async {
    final deviceId = await getDeviceId();
    final callable = _functions.httpsCallable('auth-signInOtpStepUp');
    final result = await callable.call({'username': username, 'otp': otp, 'deviceId': deviceId});
    final customToken = result.data['customToken'] as String;
    final credential = await _auth.signInWithCustomToken(customToken);
    return credential.user!;
  }
}

class PhoneSignInResult {
  const PhoneSignInResult({required this.user, required this.isNewUser});
  final User user;
  final bool isNewUser;
}

/// Thrown by [AuthRepository.signIn] when the credentials are correct but
/// this device isn't recognized — carries the account's phone number so
/// the caller can immediately call requestPhoneOtp(phone) to start the
/// step-up flow without asking the user to re-enter it.
class StepUpRequired implements Exception {
  const StepUpRequired(this.phone);
  final String phone;
}
