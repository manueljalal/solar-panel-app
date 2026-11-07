import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db, auth } from "../shared/firebase";
import { consumePhoneOtp } from "../shared/auth/verify_otp";
import { normalizeUsername, verifyPassword } from "../shared/auth/password";
import { resolveAccountUids } from "../shared/auth/resolve_account";
import { LIMITS, addHit, clearHits, clientIp, enforceRateLimit, recentHits } from "../shared/rate_limit";
import { cleanDeviceId, FAILED_WINDOW, MAX_FAILED_SIGNINS } from "../shared/auth/sign_in_guard";

interface StepUpInput {
  username: string;
  password: string;
  otp: string; // code sent by requestPhoneOtp to this user's phone on file
  deviceId: string;
}

/// Completes the step-up signIn demands when it sees an unrecognized
/// deviceId: the client already called requestPhoneOtp (against the
/// phone number on this user's profile) before calling this. On a
/// correct code, this device is added to knownDeviceIds permanently —
/// future signIns from it won't need OTP again — and a token is issued.
///
/// The password is checked again here, not just the code: signIn issues
/// no ticket when it asks for the step-up, so without this re-check the
/// username plus a code from that phone would be enough to get in, and a
/// new device would need only one factor instead of two. Wrong passwords
/// count toward the same lockout as signIn.
export const signInOtpStepUp = onCall<StepUpInput>({ region: "us-central1" }, async (request) => {
  await enforceRateLimit(`stepup:${clientIp(request)}`, 30, 15 * LIMITS.MINUTE);
  const username = normalizeUsername(request.data?.username ?? "");
  const password = request.data?.password ?? "";
  const otp = request.data?.otp?.trim();
  const deviceId = cleanDeviceId(request.data?.deviceId);

  if (!username || !password || !otp || !deviceId) {
    throw new HttpsError("invalid-argument", "username, password, otp, and deviceId are required.");
  }

  const failKey = `signin-fail:${username}`;
  if ((await recentHits(failKey, FAILED_WINDOW)) >= MAX_FAILED_SIGNINS) {
    throw new HttpsError("resource-exhausted", "Too many incorrect attempts. Try again in 15 minutes.");
  }

  // An email can match several accounts (repeat applications); the
  // password picks the account, exactly as in signIn.
  let uid: string | null = null;
  let phone: string | null = null;
  for (const candidate of await resolveAccountUids(username)) {
    const data = (await db.collection("users").doc(candidate).get()).data();
    if (!data || typeof data.passwordHash !== "string" || typeof data.phone !== "string") continue;
    if (await verifyPassword(password, data.passwordHash)) {
      uid = candidate;
      phone = data.phone;
      break;
    }
  }
  if (!uid || !phone) {
    await addHit(failKey, FAILED_WINDOW);
    throw new HttpsError("permission-denied", "Incorrect username or password.");
  }

  // Throws on a wrong / expired / exhausted code.
  await consumePhoneOtp(phone, otp);
  await clearHits(failKey);

  await db.collection("users").doc(uid).update({
    knownDeviceIds: FieldValue.arrayUnion(deviceId),
    lastSignInAt: FieldValue.serverTimestamp(),
  });

  const customToken = await auth.createCustomToken(uid);
  return { customToken };
});
