import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import { db, auth } from "../shared/firebase";
import { requireRole } from "../shared/auth/require_role";
import { cleanText } from "../shared/validation/sanitize";

const E164_PATTERN = /^\+[1-9]\d{6,14}$/;

async function deleteWhere(collection: string, field: string, value: string): Promise<number> {
  const snap = await db.collection(collection).where(field, "==", value).get();
  // Batches are capped at 500 writes.
  for (let i = 0; i < snap.docs.length; i += 400) {
    const batch = db.batch();
    snap.docs.slice(i, i + 400).forEach((d) => batch.delete(d.ref));
    await batch.commit();
  }
  return snap.size;
}

/// Admin: what account (if any) holds this phone / uid — shown before the
/// admin confirms a deletion. Finds leftover Auth accounts with no profile
/// too, which the Users list can't show.
export const findAccount = onCall<{ uid?: string; phone?: string }>({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);
  const uid = await resolveUid(request.data);
  if (!uid) return { account: null };
  const [authUser, profile, vendors] = await Promise.all([
    auth.getUser(uid).catch(() => null),
    db.collection("users").doc(uid).get(),
    db.collection("vendors").where("ownerUid", "==", uid).get(),
  ]);
  return {
    account: {
      uid,
      phone: authUser?.phoneNumber ?? profile.data()?.phone ?? null,
      name: profile.data()?.name ?? authUser?.displayName ?? null,
      username: profile.data()?.username ?? null,
      role: (authUser?.customClaims?.role as string | undefined) ?? "customer",
      hasProfile: profile.exists,
      vendorNames: vendors.docs.map((v) => v.data().businessName as string),
    },
  };
});

/// Admin: permanently deletes an account — Firebase Auth login, profile,
/// username, pending applications and, for a vendor, its company, products
/// and B2B posts. Orders and quote requests are kept as business records.
/// Admin accounts can't be deleted this way.
export const deleteAccount = onCall<{ uid?: string; phone?: string }>({ region: "us-central1" }, async (request) => {
  const { uid: callerUid } = requireRole(request, ["super_admin"]);
  const uid = await resolveUid(request.data);
  if (!uid) throw new HttpsError("not-found", "No account found.");
  if (uid === callerUid) throw new HttpsError("failed-precondition", "You can't delete your own account.");

  const authUser = await auth.getUser(uid).catch(() => null);
  const profile = await db.collection("users").doc(uid).get();
  if (authUser?.customClaims?.role === "super_admin" || profile.data()?.role === "super_admin") {
    throw new HttpsError("permission-denied", "Admin accounts can't be deleted here.");
  }

  const removed: Record<string, number> = {};
  const vendors = await db.collection("vendors").where("ownerUid", "==", uid).get();
  for (const v of vendors.docs) {
    removed.products = (removed.products ?? 0) + (await deleteWhere("products", "vendorId", v.id));
    removed.bulkListings = (removed.bulkListings ?? 0) + (await deleteWhere("bulkListings", "vendorId", v.id));
    removed.bulkRequests = (removed.bulkRequests ?? 0) + (await deleteWhere("bulkRequests", "vendorId", v.id));
    await v.ref.delete();
  }
  removed.vendors = vendors.size;
  removed.applications = await deleteWhere("vendorApplications", "uid", uid);
  removed.usernames = await deleteWhere("usernames", "uid", uid);
  if (profile.exists) await profile.ref.delete();
  // Auth last: if anything above fails, the login still exists and the
  // admin can simply retry the deletion.
  if (authUser) await auth.deleteUser(uid);

  logger.warn("Account deleted by admin", { uid, by: callerUid, removed });
  return { ok: true, removed };
});

async function resolveUid(data: { uid?: string; phone?: string } | undefined): Promise<string | null> {
  if (data?.uid) return cleanText(data.uid, "uid", { max: 128, min: 1 });
  const phone = data?.phone?.trim() ?? "";
  if (!E164_PATTERN.test(phone)) throw new HttpsError("invalid-argument", "Enter a full phone number, e.g. +9647501234567.");
  const byAuth = await auth.getUserByPhoneNumber(phone).catch(() => null);
  if (byAuth) return byAuth.uid;
  const byProfile = await db.collection("users").where("phone", "==", phone).limit(1).get();
  return byProfile.empty ? null : byProfile.docs[0].id;
}
