import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { randomUUID } from "crypto";
import { db, auth } from "../shared/firebase";
import { consumePhoneOtp } from "../shared/auth/verify_otp";
import { hashPassword, isValidPassword, isValidUsername, normalizeUsername } from "../shared/auth/password";
import { logger } from "firebase-functions";
import { findPhoneAccount, isUsernameAvailable, removeOrphanAccount } from "../shared/auth/signup_checks";
import { LIMITS, clientIp, enforceRateLimit } from "../shared/rate_limit";
import { cleanText } from "../shared/validation/sanitize";
import { cleanDeviceId } from "../shared/auth/sign_in_guard";

interface PickedLocationInput {
  latitude: number;
  longitude: number;
  address: string;
}

interface SignUpInput {
  name: string;
  username: string;
  password: string;
  phone: string; // E.164
  otp: string; // code sent by requestPhoneOtp to `phone`
  location?: PickedLocationInput;
  deviceId?: string;
}

const E164_PATTERN = /^\+[1-9]\d{6,14}$/;

/// The picked map location, or null. Stored on the profile as-is, so it is
/// rebuilt from checked fields rather than trusting the client's object.
function cleanLocation(raw: unknown): { latitude: number; longitude: number; address: string } | null {
  if (raw === undefined || raw === null) return null;
  const { latitude, longitude, address } = raw as Partial<PickedLocationInput>;
  if (
    typeof latitude !== "number" || typeof longitude !== "number" ||
    !(latitude >= -90 && latitude <= 90) || !(longitude >= -180 && longitude <= 180)
  ) {
    throw new HttpsError("invalid-argument", "location is invalid.");
  }
  return { latitude, longitude, address: cleanText(address, "address", { max: 300 }) };
}

/// Real registration: name + username + password + phone, with the phone
/// number proven via a WhatsApp-delivered OTP (requestPhoneOtp must have
/// been called first) in the SAME request as setting the password — so a
/// username+password account can't be created without ever proving phone
/// ownership. Password is hashed with bcrypt and stored on the user's own
/// users/{uid} doc; Firebase Auth itself has no password set for this
/// user (we mint custom tokens instead, the same mechanism the phone-only
/// flow already uses), since the credential check is entirely our own.
export const signUp = onCall<SignUpInput>({ region: "us-central1" }, async (request) => {
    await enforceRateLimit(`signup:${clientIp(request)}`, 10, LIMITS.HOUR);
  const name = cleanText(request.data?.name, "name", { max: 80, min: 1 });
  const username = normalizeUsername(request.data?.username ?? "");
  const password = request.data?.password ?? "";
  const phone = request.data?.phone?.trim();
  const otp = request.data?.otp?.trim();
  const location = cleanLocation(request.data?.location);
  const deviceId = cleanDeviceId(request.data?.deviceId);

  if (!isValidUsername(username)) {
    throw new HttpsError(
      "invalid-argument",
      "username must be 3-20 characters: lowercase letters, numbers, underscores only.",
    );
  }
  if (!isValidPassword(password)) {
    throw new HttpsError(
      "invalid-argument",
      "password must be at least 8 characters and include an uppercase letter, a lowercase letter, a number, and a symbol.",
    );
  }
  if (!phone || !E164_PATTERN.test(phone)) {
    throw new HttpsError("invalid-argument", "phone must be in E.164 format, e.g. +9647501234567.");
  }
  if (!otp) throw new HttpsError("invalid-argument", "otp is required.");

  // Cheap and non-destructive, so do it before the one-time code is spent:
  // a taken username must not cost the user a WhatsApp code.
  if (!(await isUsernameAvailable(username))) {
    throw new HttpsError("already-exists", "That username is taken.");
  }

  // A phone that already has a real account is refused before the code is
  // spent, too.
  const existing = await findPhoneAccount(phone);
  if (existing && !existing.orphan) {
    throw new HttpsError("already-exists", "An account with that phone number already exists.");
  }

  // Prove phone ownership BEFORE reserving the username / creating
  // anything — a failed OTP check should leave no trace.
  await consumePhoneOtp(phone, otp);

  // The caller now provably owns this phone, so a leftover Auth account
  // from an earlier interrupted sign-up (no profile, no role) is removed
  // instead of blocking the number forever.
  if (existing?.orphan) await removeOrphanAccount(existing.uid);

  const usernameRef = db.collection("usernames").doc(username);
  const uid = randomUUID();

  // Username reservation happens before createUser/createCustomToken so
  // "That username is taken" still fails cleanly with nothing else
  // created — but everything AFTER this point must succeed-or-rollback
  // together. createCustomToken in particular depends on IAM
  // (roles/iam.serviceAccountTokenCreator on the function's own service
  // account) and can fail independently of everything else; a prior
  // version of this function called it LAST, after createUser + the
  // Firestore profile write, so an IAM failure there left a real,
  // permanent account behind with no token ever returned — the client
  // saw a hard failure while the account had actually been created,
  // and a retry then failed with "username taken" against an account
  // the user never knew existed. Minting the token FIRST (right after
  // reserving the username, before any other persistent write) means a
  // late failure here can't leave an orphaned account: if this throws,
  // we roll back the username reservation ourselves before rethrowing.
  await db.runTransaction(async (tx) => {
    const usernameSnap = await tx.get(usernameRef);
    if (usernameSnap.exists) {
      // Taken only if it belongs to a real account; an orphaned
      // reservation (interrupted earlier sign-up) is reclaimed.
      const owner = usernameSnap.data()?.uid as string | undefined;
      const ownerExists = owner ? (await tx.get(db.collection("users").doc(owner))).exists : false;
      if (ownerExists) {
        throw new HttpsError("already-exists", "That username is taken.");
      }
    }
    tx.set(usernameRef, { uid, createdAt: FieldValue.serverTimestamp() });
  });

  let customToken: string;
  try {
    customToken = await auth.createCustomToken(uid);
  } catch (e) {
    await usernameRef.delete();
    throw e;
  }

  const passwordHash = await hashPassword(password);

  // The account only counts as created once BOTH the Auth user and the
  // users/{uid} profile exist. If either step fails, everything written so
  // far is undone, so a failed sign-up never leaves an Auth account holding
  // the phone number (which used to make the number unusable afterwards).
  let authCreated = false;
  try {
    await auth.createUser({ uid, displayName: name, phoneNumber: phone });
    authCreated = true;
    await db
      .collection("users")
      .doc(uid)
      .set({
        name,
        username,
        passwordHash,
        phone,
        location,
        role: "customer",
        knownDeviceIds: deviceId ? [deviceId] : [],
        createdAt: FieldValue.serverTimestamp(),
        lastSignInAt: FieldValue.serverTimestamp(),
      });
  } catch (e) {
    if (authCreated) {
      await auth.deleteUser(uid).catch((err) => logger.error("signUp rollback: deleteUser failed", { uid, err: String(err) }));
    }
    await usernameRef.delete().catch((err) => logger.error("signUp rollback: username delete failed", { uid, err: String(err) }));
    if ((e as { code?: string }).code === "auth/phone-number-already-exists") {
      throw new HttpsError("already-exists", "An account with that phone number already exists.");
    }
    throw e;
  }

  return { customToken };
});
