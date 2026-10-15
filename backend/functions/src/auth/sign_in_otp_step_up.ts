import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db, auth } from "../shared/firebase";
import { consumePhoneOtp } from "../shared/auth/verify_otp";
import { normalizeUsername } from "../shared/auth/password";
import { resolveAccountUids } from "../shared/auth/resolve_account";

interface StepUpInput {
  username: string;
  otp: string; // code sent by requestPhoneOtp to this user's phone on file
  deviceId: string;
}

/// Completes the step-up signIn demands when it sees an unrecognized
/// deviceId: the client already called requestPhoneOtp (against the
/// phone number on this user's profile) before calling this. On a
/// correct code, this device is added to knownDeviceIds permanently —
/// future signIns from it won't need OTP again — and a token is issued.
export const signInOtpStepUp = onCall<StepUpInput>({ region: "us-central1" }, async (request) => {
  const username = normalizeUsername(request.data?.username ?? "");
  const otp = request.data?.otp?.trim();
  const deviceId = request.data?.deviceId?.trim();

  if (!username || !otp || !deviceId) {
    throw new HttpsError("invalid-argument", "username, otp, and deviceId are required.");
  }

  // An email can match several accounts (repeat applications); the
  // code sent to an account's own phone decides which one this is.
  const candidates = await resolveAccountUids(username);
  if (candidates.length === 0) {
    throw new HttpsError("not-found", "Account not found.");
  }
  let uid: string | null = null;
  let lastError: unknown = null;
  for (const candidate of candidates) {
    const snap = await db.collection("users").doc(candidate).get();
    const phone = snap.data()?.phone as string | undefined;
    if (!snap.exists || !phone) continue;
    try {
      await consumePhoneOtp(phone, otp);
      uid = candidate;
      break;
    } catch (err) {
      lastError = err;
    }
  }
  if (!uid) {
    throw lastError ?? new HttpsError("not-found", "Account not found.");
  }
  const userRef = db.collection("users").doc(uid);

  await userRef.update({
    knownDeviceIds: FieldValue.arrayUnion(deviceId),
    lastSignInAt: FieldValue.serverTimestamp(),
  });

  const customToken = await auth.createCustomToken(uid);
  return { customToken };
});
