import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db, auth } from "../shared/firebase";
import { consumePhoneOtp } from "../shared/auth/verify_otp";
import { normalizeUsername } from "../shared/auth/password";

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

  const usernameSnap = await db.collection("usernames").doc(username).get();
  if (!usernameSnap.exists) {
    throw new HttpsError("not-found", "Account not found.");
  }
  const uid = usernameSnap.data()!.uid as string;

  const userRef = db.collection("users").doc(uid);
  const userSnap = await userRef.get();
  if (!userSnap.exists) {
    throw new HttpsError("not-found", "Account not found.");
  }
  const phone = userSnap.data()!.phone as string;

  await consumePhoneOtp(phone, otp);

  await userRef.update({
    knownDeviceIds: FieldValue.arrayUnion(deviceId),
    lastSignInAt: FieldValue.serverTimestamp(),
  });

  const customToken = await auth.createCustomToken(uid);
  return { customToken };
});
