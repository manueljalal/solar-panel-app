import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { db } from "../shared/firebase";
import { cleanEmail, cleanText } from "../shared/validation/sanitize";
import { hashPassword, isValidPassword, isValidUsername, normalizeUsername, verifyPassword } from "../shared/auth/password";
import { deleteAccountData } from "../shared/account_deletion";

function requireRealAccount(request: { auth?: { uid: string; token: { firebase?: { sign_in_provider?: string } } } }) {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required.");
  if (request.auth.token.firebase?.sign_in_provider === "anonymous") {
    throw new HttpsError("failed-precondition", "Sign in to your account first.");
  }
  return request.auth.uid;
}

/// The caller's own profile (users/{uid} isn't client-readable because it
/// holds the password hash — this returns only the safe fields).
export const getMyProfile = onCall({ region: "us-central1" }, async (request) => {
  const uid = requireRealAccount(request);
  const d = (await db.collection("users").doc(uid).get()).data();
  if (!d) throw new HttpsError("not-found", "Profile not found.");
  return {
    name: d.name ?? "",
    username: d.username ?? "",
    phone: d.phone ?? "",
    email: d.email ?? "",
    location: d.location ?? null,
    addressLine: d.addressLine ?? "",
  };
});

interface UpdateProfileInput {
  name?: string;
  /** New username; must be free. */
  username?: string;
  /** Optional contact / sign-in email; "" clears it. Must not belong to another account. */
  email?: string;
  location?: { latitude: number; longitude: number; address?: string } | null;
  /** Street / building / landmark for deliveries, kept with [location]. */
  addressLine?: string;
}

/// Edit the caller's own profile. The phone is not editable here — it is
/// the account's WhatsApp-verified identity.
///
/// A username change is one transaction: the new name is reserved (only if
/// free, or an orphaned reservation), the old reservation released and the
/// profile updated together, so two people can never end up holding the
/// same username and the old one can't be left dangling.
export const updateMyProfile = onCall<UpdateProfileInput>({ region: "us-central1" }, async (request) => {
  const uid = requireRealAccount(request);
  const data = request.data ?? {};
  const update: Record<string, unknown> = { updatedAt: FieldValue.serverTimestamp() };

  if (data.name !== undefined) update.name = cleanText(data.name, "name", { max: 80, min: 1 });

  if (data.email !== undefined) {
    const raw = typeof data.email === "string" ? data.email.trim() : data.email;
    if (raw === "") {
      update.email = FieldValue.delete();
    } else {
      const email = cleanEmail(raw);
      const taken = await db.collection("users").where("email", "==", email).limit(2).get();
      if (taken.docs.some((d) => d.id !== uid)) {
        throw new HttpsError("already-exists", "That email is already used by another account.");
      }
      update.email = email;
    }
  }

  if (data.addressLine !== undefined) update.addressLine = cleanText(data.addressLine, "addressLine", { max: 300 });

  const loc = data.location;
  if (loc !== undefined) {
    if (loc === null) {
      update.location = null;
    } else {
      const { latitude, longitude } = loc;
      if (
        typeof latitude !== "number" || typeof longitude !== "number" ||
        !(latitude >= -90 && latitude <= 90) || !(longitude >= -180 && longitude <= 180)
      ) {
        throw new HttpsError("invalid-argument", "location is invalid.");
      }
      update.location = { latitude, longitude, address: cleanText(loc.address, "address", { max: 300 }) };
    }
  }

  const userRef = db.collection("users").doc(uid);
  let newUsername: string | null = null;
  if (data.username !== undefined) {
    newUsername = normalizeUsername(data.username);
    if (!isValidUsername(newUsername)) {
      throw new HttpsError("invalid-argument", "Username: 3-20 characters, lowercase letters, numbers, underscores.");
    }
  }

  await db.runTransaction(async (tx) => {
    const profile = await tx.get(userRef);
    if (!profile.exists) throw new HttpsError("not-found", "Profile not found.");
    const current = profile.data()?.username as string | undefined;

    if (newUsername && newUsername !== current) {
      const newRef = db.collection("usernames").doc(newUsername);
      const reserved = await tx.get(newRef);
      if (reserved.exists) {
        const owner = reserved.data()?.uid as string | undefined;
        const ownerProfile = owner && owner !== uid ? await tx.get(db.collection("users").doc(owner)) : null;
        if (owner !== uid && ownerProfile?.exists) {
          throw new HttpsError("already-exists", "That username is taken.");
        }
      }
      tx.set(newRef, { uid, createdAt: FieldValue.serverTimestamp() });
      if (current) tx.delete(db.collection("usernames").doc(current));
      update.username = newUsername;
    }
    tx.update(userRef, update);
  });
  return { ok: true };
});

const MAX_PASSWORD_FAILURES = 5;
const PASSWORD_LOCK_MS = 15 * 60 * 1000;

/// Change the caller's password. Requires the current one; after 5 wrong
/// attempts, password changes are blocked for 15 minutes so a borrowed
/// unlocked phone can't be used to guess it.
export const changePassword = onCall<{ currentPassword: string; newPassword: string }>(
  { region: "us-central1" },
  async (request) => {
    const uid = requireRealAccount(request);
    const currentPassword = request.data?.currentPassword ?? "";
    const newPassword = request.data?.newPassword ?? "";
    if (typeof currentPassword !== "string" || typeof newPassword !== "string" || !currentPassword) {
      throw new HttpsError("invalid-argument", "Enter your current password.");
    }
    if (!isValidPassword(newPassword)) {
      throw new HttpsError(
        "invalid-argument",
        "New password must be at least 8 characters with an uppercase letter, a lowercase letter, a number, and a symbol.",
      );
    }
    if (newPassword === currentPassword) {
      throw new HttpsError("invalid-argument", "Choose a password different from your current one.");
    }

    const ref = db.collection("users").doc(uid);
    const user = (await ref.get()).data();
    if (!user?.passwordHash) throw new HttpsError("failed-precondition", "This account has no password set.");

    const lockedUntil = (user.passwordLockedUntil as { toMillis?: () => number } | undefined)?.toMillis?.() ?? 0;
    if (lockedUntil > Date.now()) {
      throw new HttpsError("resource-exhausted", "Too many wrong attempts. Try again in a few minutes.");
    }

    if (!(await verifyPassword(currentPassword, user.passwordHash))) {
      const failures = ((user.passwordFailures as number | undefined) ?? 0) + 1;
      await ref.update(
        failures >= MAX_PASSWORD_FAILURES
          ? { passwordFailures: 0, passwordLockedUntil: new Date(Date.now() + PASSWORD_LOCK_MS) }
          : { passwordFailures: failures },
      );
      throw new HttpsError("permission-denied", "Your current password is incorrect.");
    }

    await ref.update({
      passwordHash: await hashPassword(newPassword),
      passwordFailures: 0,
      passwordLockedUntil: FieldValue.delete(),
      passwordChangedAt: FieldValue.serverTimestamp(),
    });
    logger.info("Password changed", { uid });
    return { ok: true };
  },
);

/// In-app account deletion (required by the App Store for apps that let
/// people create accounts). Customers delete themselves; a vendor account
/// is closed through support, since it also removes a company and its
/// catalogue.
export const deleteMyAccount = onCall({ region: "us-central1" }, async (request) => {
  const uid = requireRealAccount(request);
  const role = request.auth?.token.role;
  if (role === "vendor" || role === "super_admin") {
    throw new HttpsError("failed-precondition", "Business accounts are closed through support — contact us and we'll do it for you.");
  }
  const removed = await deleteAccountData(uid);
  logger.warn("Account deleted by its owner", { uid, removed });
  return { ok: true };
});
