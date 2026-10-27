import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { db } from "../shared/firebase";
import { cleanText } from "../shared/validation/sanitize";
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
  };
});

/// Edit name and/or saved location.
export const updateMyProfile = onCall<{ name?: string; location?: { latitude: number; longitude: number; address?: string } | null }>(
  { region: "us-central1" },
  async (request) => {
    const uid = requireRealAccount(request);
    const update: Record<string, unknown> = { updatedAt: FieldValue.serverTimestamp() };
    if (request.data?.name !== undefined) update.name = cleanText(request.data.name, "name", { max: 80, min: 1 });
    const loc = request.data?.location;
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
    await db.collection("users").doc(uid).update(update);
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
