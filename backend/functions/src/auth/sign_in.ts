import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import { FieldValue } from "firebase-admin/firestore";
import { db, auth } from "../shared/firebase";
import { verifyPassword, normalizeUsername } from "../shared/auth/password";
import { resolveAccountUids } from "../shared/auth/resolve_account";

interface SignInInput {
  username: string;
  password: string;
  deviceId?: string;
}

/// Real sign-in: username + password, checked against the bcrypt hash on
/// users/{uid} (see sign_up.ts — there is no Firebase Auth password for
/// this user, the check is entirely ours). If the calling device isn't
/// in that user's knownDeviceIds, this refuses with a distinct error
/// code (`step-up-required`) instead of a token — the client is expected
/// to fall back to requestPhoneOtp + signInWithOtpStepUp to prove the
/// device before getting in. A device IS trusted (and skips OTP) once
/// it's been through that step-up once, or was present at signup.
export const signIn = onCall<SignInInput>({ region: "us-central1" }, async (request) => {
  const username = normalizeUsername(request.data?.username ?? "");
  const password = request.data?.password ?? "";
  const deviceId = request.data?.deviceId?.trim() || null;

  if (!username || !password) {
    throw new HttpsError("invalid-argument", "username and password are required.");
  }
  // Required, not optional: an omitted deviceId used to skip the step-up
  // check below entirely, turning "unknown device needs OTP" into
  // "just don't send a device id".
  if (!deviceId) {
    throw new HttpsError("invalid-argument", "deviceId is required.");
  }

  // `username` may also be the vendor's application email — see
  // resolveAccountUids. Several accounts can share one email (repeat
  // applications), so the password picks the right one.
  const uids = await resolveAccountUids(username);
  let uid: string | null = null;
  let userRef = db.collection("users").doc("_");
  let user: FirebaseFirestore.DocumentData | null = null;
  for (const candidate of uids) {
    const ref = db.collection("users").doc(candidate);
    const snap = await ref.get();
    const data = snap.data();
    if (!snap.exists || !data || typeof data.passwordHash !== "string") continue;
    if (await verifyPassword(password, data.passwordHash)) {
      uid = candidate;
      userRef = ref;
      user = data;
      break;
    }
  }
  if (!uid || !user) {
    // Reason goes to the server log only — the client always gets the same
    // generic message so sign-in can't be used to probe for accounts.
    logger.warn("signIn rejected", {
      identifierKind: username.includes("@") ? "email" : "username",
      candidates: uids.length,
      reason: uids.length === 0 ? "no-matching-account" : "password-mismatch",
    });
    // Same message whether the account is unknown or the password is
    // wrong — don't reveal which.
    throw new HttpsError("permission-denied", "Incorrect username or password.");
  }

  // Suspended by an admin (admin-setUserDisabled). Checked only after
  // the password matched, so it doesn't reveal anything to a guesser.
  if (user.disabled === true) {
    throw new HttpsError("permission-denied", "This account is suspended. Contact support.");
  }

  const knownDeviceIds = (user.knownDeviceIds ?? []) as string[];
  if (!knownDeviceIds.includes(deviceId)) {
    // Correct credentials, unrecognized device — require a fresh phone
    // OTP (via requestPhoneOtp + signInWithOtpStepUp) before minting a
    // token. No token is issued here.
    //
    // The phone number is encoded directly in the message string
    // ("step-up-required:+9647...") rather than passed via HttpsError's
    // `details` param — `details` does NOT reliably reach the Flutter
    // client over the callable HTTP transport (confirmed: a client
    // calling this function got only {message, status} back, details
    // was silently dropped), so relying on it left the client unable to
    // ever start the step-up flow — every step-up case fell through to
    // a generic "couldn't sign in" error instead. message is proven to
    // arrive intact, so that's what carries the data now.
    throw new HttpsError("failed-precondition", `step-up-required:${user.phone}`);
  }

  await userRef.update({ lastSignInAt: FieldValue.serverTimestamp() });

  const customToken = await auth.createCustomToken(uid);
  return { customToken };
});
