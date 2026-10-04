import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db, auth } from "../shared/firebase";
import { consumePhoneOtp } from "../shared/auth/verify_otp";

interface PickedLocationInput {
  latitude: number;
  longitude: number;
  address: string;
}

interface VerifyOtpInput {
  phone: string;
  otp: string;
  name?: string; // only used on first-time account creation
  deviceId?: string;
  location?: PickedLocationInput; // only used on first-time account creation
}

/// Verifies a code sent by requestPhoneOtp and, on success, returns a
/// Firebase custom token the client exchanges via
/// signInWithCustomToken — this is how phone-based sign-in works without
/// Firebase's own (SMS-only) Phone Auth provider, since delivery goes
/// through WhatsApp instead.
///
/// Compares hashes with a constant-time check (crypto.timingSafeEqual)
/// rather than `===`, since this is exactly the kind of secret-comparison
/// where a timing side-channel is a real (if narrow) risk.
export const verifyPhoneOtp = onCall<VerifyOtpInput>({ region: "us-central1" }, async (request) => {
  const phone = request.data?.phone?.trim();
  const otp = request.data?.otp?.trim();
  const name = request.data?.name?.trim() || null;
  const deviceId = request.data?.deviceId?.trim() || null;
  const location = request.data?.location ?? null;
  if (!phone || !otp) {
    throw new HttpsError("invalid-argument", "phone and otp are required.");
  }

  await consumePhoneOtp(phone, otp);
  // Deterministic uid from the phone number so the same number always
  // maps to the same Firebase account across verifications.
  const phoneUid = `phone:${phone}`;

  // Ensure a user record exists for this phone number (first-time
  // verification creates it; repeat verification reuses it). The uid is
  // normally the phone-derived one, but a phone number can already be
  // attached to a DIFFERENT uid — e.g. an account created by signUp(),
  // which mints a random uid rather than the phone-derived one — so
  // createUser can collide on the phone number even though no
  // `phone:${phone}` user exists yet. Firebase Auth enforces phone
  // numbers as globally unique, so that pre-existing account is who this
  // number really belongs to: reuse its uid instead of failing, rather
  // than trying to split one phone number across two uids.
  let uid = phoneUid;
  let isNewUser = false;
  try {
    await auth.getUser(phoneUid);
  } catch {
    try {
      await auth.createUser({ uid: phoneUid, phoneNumber: phone, displayName: name ?? undefined });
      isNewUser = true;
    } catch (err) {
      if ((err as { code?: string }).code !== "auth/phone-number-already-exists") {
        throw err;
      }
      uid = (await auth.getUserByPhoneNumber(phone)).uid;
    }
  }

  // users/{uid} profile doc — created on first verification, device trail
  // appended on every verification (not just the first) so a later
  // sign-in from a brand-new device is a visible signal, not silent.
  const userRef = db.collection("users").doc(uid);
  await userRef.set(
    {
      phone,
      ...(isNewUser ? { name: name ?? null, location, createdAt: FieldValue.serverTimestamp() } : {}),
      lastSignInAt: FieldValue.serverTimestamp(),
      ...(deviceId ? { knownDeviceIds: FieldValue.arrayUnion(deviceId) } : {}),
    },
    { merge: true },
  );

  const customToken = await auth.createCustomToken(uid);
  return { customToken, isNewUser };
});
