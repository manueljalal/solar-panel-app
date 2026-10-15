import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import { FieldValue } from "firebase-admin/firestore";
import { db, auth } from "../shared/firebase";
import { consumePhoneOtp } from "../shared/auth/verify_otp";
import { issuePhoneOtp } from "../shared/auth/issue_otp";
import { hashPassword, isValidPassword, verifyPassword } from "../shared/auth/password";
import { resolveAccountUids } from "../shared/auth/resolve_account";
import { whatsappAccessToken } from "../shared/whatsapp/send_otp";
import { cleanText } from "../shared/validation/sanitize";

const PASSWORD_RULE =
  "password must be at least 8 characters and include an uppercase letter, a lowercase letter, a number, and a symbol.";

function requireRegistered(request: { auth?: { uid: string; token: { firebase?: { sign_in_provider?: string } } } }) {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required.");
  if (request.auth.token.firebase?.sign_in_provider === "anonymous") {
    throw new HttpsError("failed-precondition", "Create an account first.");
  }
  return request.auth.uid;
}

/// Step 1 of "Forgot password": sends a WhatsApp code to the phone on file
/// for the given username (or vendor email). Always answers the same way
/// whether or not the account exists, so this can't be used to discover
/// accounts or phone numbers — the client says "if that account exists, we
/// sent a code to its WhatsApp".
export const requestPasswordReset = onCall<{ identifier: string; deviceId?: string }>(
  { region: "us-central1", secrets: [whatsappAccessToken] },
  async (request) => {
    const identifier = cleanText(request.data?.identifier, "identifier", { max: 254, min: 1 });
    const deviceId = request.data?.deviceId?.trim() || null;

    const uids = await resolveAccountUids(identifier);
    const phones = new Set<string>();
    for (const uid of uids) {
      const phone = (await db.collection("users").doc(uid).get()).data()?.phone;
      if (typeof phone === "string") phones.add(phone);
    }
    for (const phone of phones) {
      try {
        await issuePhoneOtp(phone, deviceId);
      } catch (e) {
        // Rate limits etc. stay server-side; surfacing them would reveal
        // that the account exists.
        logger.warn("requestPasswordReset send failed", { code: (e as { code?: string }).code });
      }
    }
    return { ok: true };
  },
);

interface ResetPasswordInput {
  identifier: string;
  otp: string;
  newPassword: string;
  deviceId: string;
}

/// Step 2 of "Forgot password": proves the phone with the code from
/// requestPasswordReset, sets the new password, trusts this device, ends
/// every other session, and signs the caller in (returns a custom token).
export const resetPassword = onCall<ResetPasswordInput>({ region: "us-central1" }, async (request) => {
  const identifier = cleanText(request.data?.identifier, "identifier", { max: 254, min: 1 });
  const otp = request.data?.otp?.trim();
  const newPassword = request.data?.newPassword ?? "";
  const deviceId = request.data?.deviceId?.trim();
  if (!otp || !deviceId) throw new HttpsError("invalid-argument", "otp and deviceId are required.");
  if (!isValidPassword(newPassword)) throw new HttpsError("invalid-argument", PASSWORD_RULE);

  let uid: string | null = null;
  let lastError: unknown = null;
  for (const candidate of await resolveAccountUids(identifier)) {
    const phone = (await db.collection("users").doc(candidate).get()).data()?.phone as string | undefined;
    if (!phone) continue;
    try {
      await consumePhoneOtp(phone, otp);
      uid = candidate;
      break;
    } catch (err) {
      lastError = err;
    }
  }
  if (!uid) throw lastError ?? new HttpsError("permission-denied", "Incorrect code.");

  const userRef = db.collection("users").doc(uid);
  if ((await userRef.get()).data()?.disabled === true) {
    throw new HttpsError("permission-denied", "This account is suspended. Contact support.");
  }
  await userRef.update({
    passwordHash: await hashPassword(newPassword),
    knownDeviceIds: FieldValue.arrayUnion(deviceId),
    passwordChangedAt: FieldValue.serverTimestamp(),
    lastSignInAt: FieldValue.serverTimestamp(),
  });
  await auth.revokeRefreshTokens(uid);
  return { customToken: await auth.createCustomToken(uid) };
});

/// The caller's own profile, without passwordHash / knownDeviceIds (which
/// is why users/{uid} isn't client-readable at all).
export const getMyProfile = onCall({ region: "us-central1" }, async (request) => {
  const uid = requireRegistered(request);
  const data = (await db.collection("users").doc(uid).get()).data();
  if (!data) throw new HttpsError("not-found", "Profile not found.");
  return {
    uid,
    name: data.name ?? "",
    username: data.username ?? "",
    phone: data.phone ?? "",
    email: data.email ?? "",
    location: data.location ?? null,
    role: data.role ?? "customer",
  };
});

interface UpdateMyProfileInput {
  name?: string;
  location?: { latitude: number; longitude: number; address: string } | null;
}

/// Edit display name and saved location. Username and phone are identity —
/// they don't change here.
export const updateMyProfile = onCall<UpdateMyProfileInput>({ region: "us-central1" }, async (request) => {
  const uid = requireRegistered(request);
  const update: Record<string, unknown> = {};
  if (request.data?.name !== undefined) {
    update.name = cleanText(request.data.name, "name", { max: 80, min: 1 });
  }
  if (request.data?.location !== undefined) {
    const loc = request.data.location;
    if (loc === null) {
      update.location = null;
    } else if (
      typeof loc?.latitude === "number" && Math.abs(loc.latitude) <= 90 &&
      typeof loc?.longitude === "number" && Math.abs(loc.longitude) <= 180
    ) {
      update.location = {
        latitude: loc.latitude,
        longitude: loc.longitude,
        address: cleanText(loc.address, "address", { max: 300 }),
      };
    } else {
      throw new HttpsError("invalid-argument", "location is invalid.");
    }
  }
  if (Object.keys(update).length === 0) throw new HttpsError("invalid-argument", "Nothing to update.");

  await db.collection("users").doc(uid).update(update);
  if (typeof update.name === "string") await auth.updateUser(uid, { displayName: update.name });
  return { ok: true };
});

/// Change password while signed in — needs the current one.
export const changePassword = onCall<{ currentPassword: string; newPassword: string }>(
  { region: "us-central1" },
  async (request) => {
    const uid = requireRegistered(request);
    const userRef = db.collection("users").doc(uid);
    const hash = (await userRef.get()).data()?.passwordHash;
    if (typeof hash !== "string" || !(await verifyPassword(request.data?.currentPassword ?? "", hash))) {
      throw new HttpsError("permission-denied", "Current password is incorrect.");
    }
    const newPassword = request.data?.newPassword ?? "";
    if (!isValidPassword(newPassword)) throw new HttpsError("invalid-argument", PASSWORD_RULE);
    await userRef.update({
      passwordHash: await hashPassword(newPassword),
      passwordChangedAt: FieldValue.serverTimestamp(),
    });
    return { ok: true };
  },
);

/// Permanently deletes the caller's account (app-store requirement).
/// Requires the password as confirmation. Orders are kept for the
/// vendor's records but stripped of the customer's name and phone; quote
/// requests are deleted; reviews stay, without a name. Vendor and admin
/// accounts must go through support instead — deleting them would orphan
/// a business or lock the platform out.
export const deleteMyAccount = onCall<{ password: string }>({ region: "us-central1" }, async (request) => {
  const uid = requireRegistered(request);
  const role = request.auth!.token.role as string | undefined;
  if (role === "vendor" || role === "super_admin") {
    throw new HttpsError("failed-precondition", "Business and admin accounts are closed through support.");
  }

  const userRef = db.collection("users").doc(uid);
  const user = (await userRef.get()).data();
  if (!user || typeof user.passwordHash !== "string" || !(await verifyPassword(request.data?.password ?? "", user.passwordHash))) {
    throw new HttpsError("permission-denied", "Password is incorrect.");
  }

  const [orders, quotes, reviews] = await Promise.all([
    db.collection("orders").where("customerId", "==", uid).get(),
    db.collection("quoteRequests").where("uid", "==", uid).get(),
    db.collection("reviews").where("customerId", "==", uid).get(),
  ]);

  const writer = db.bulkWriter();
  orders.docs.forEach((d) =>
    writer.update(d.ref, {
      contact: { name: "Deleted account", phone: "" },
      customerDeleted: true,
      updatedAt: FieldValue.serverTimestamp(),
    }),
  );
  quotes.docs.forEach((d) => writer.delete(d.ref));
  reviews.docs.forEach((d) => writer.update(d.ref, { reviewerName: "" }));
  if (typeof user.username === "string") writer.delete(db.collection("usernames").doc(user.username));
  writer.delete(userRef);
  await writer.close();

  await auth.deleteUser(uid);
  return { ok: true };
});
