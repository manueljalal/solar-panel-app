import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db, auth } from "../shared/firebase";
import { requireRole } from "../shared/auth/require_role";
import { normalizeUsername } from "../shared/auth/password";
import { toMillis } from "../shared/orders/order_store";
import { cleanDocId, cleanEnum, cleanText } from "../shared/validation/sanitize";

/// Public-safe view of users/{uid}: never passwordHash or knownDeviceIds.
function toUserSummary(id: string, data: FirebaseFirestore.DocumentData) {
  return {
    uid: id,
    name: data.name ?? "",
    username: data.username ?? "",
    phone: data.phone ?? "",
    email: data.email ?? "",
    role: data.role ?? "customer",
    disabled: data.disabled === true,
    createdAt: toMillis(data.createdAt),
    lastSignInAt: toMillis(data.lastSignInAt),
  };
}

interface ListUsersInput {
  /** Exact username, phone (E.164) or email. Omit for the newest accounts. */
  query?: string;
  /** createdAt millis of the last row from the previous page. */
  before?: number;
}

/// Admin-only: registered (non-guest) accounts. Anonymous guests have no
/// users/{uid} doc and so never appear here.
export const listUsers = onCall<ListUsersInput>({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);
  const q = cleanText(request.data?.query, "query", { max: 254 });
  const users = db.collection("users");

  if (q) {
    const value = q.startsWith("+") ? q : normalizeUsername(q);
    const field = value.startsWith("+") ? "phone" : value.includes("@") ? "email" : "username";
    const snap = await users.where(field, "==", value).limit(20).get();
    return { users: snap.docs.map((d) => toUserSummary(d.id, d.data())), hasMore: false };
  }

  const PAGE = 50;
  let query = users.orderBy("createdAt", "desc").limit(PAGE + 1);
  if (typeof request.data?.before === "number") query = query.startAfter(new Date(request.data.before));
  const snap = await query.get();
  const docs = snap.docs.slice(0, PAGE);
  return { users: docs.map((d) => toUserSummary(d.id, d.data())), hasMore: snap.docs.length > PAGE };
});

/// Admin-only: suspend or restore an account. Disabling also revokes its
/// refresh tokens so existing sessions end within the hour, and the
/// account can't mint new ones (signIn checks `disabled`).
export const setUserDisabled = onCall<{ uid: string; disabled: boolean }>({ region: "us-central1" }, async (request) => {
  const { uid: callerUid } = requireRole(request, ["super_admin"]);
  const uid = cleanDocId(request.data?.uid, "uid");
  const disabled = request.data?.disabled === true;
  if (uid === callerUid) throw new HttpsError("failed-precondition", "You can't suspend your own account.");

  await auth.updateUser(uid, { disabled });
  if (disabled) await auth.revokeRefreshTokens(uid);
  await db.collection("users").doc(uid).set({ disabled, disabledAt: disabled ? FieldValue.serverTimestamp() : null }, { merge: true });
  return { ok: true };
});

/// Admin-only: promote another registered account to super_admin, or
/// demote one back to customer. The "future admin-only promote callable"
/// bootstrapSuperAdmin's comment refers to. Vendor role is never granted
/// here — that only comes from approving an application.
export const setAdminRole = onCall<{ uid: string; admin: boolean }>({ region: "us-central1" }, async (request) => {
  const { uid: callerUid } = requireRole(request, ["super_admin"]);
  const uid = cleanDocId(request.data?.uid, "uid");
  const makeAdmin = request.data?.admin === true;
  if (uid === callerUid && !makeAdmin) throw new HttpsError("failed-precondition", "You can't remove your own admin role.");

  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists) throw new HttpsError("not-found", "Only registered accounts can be admins.");

  const user = await auth.getUser(uid);
  const claims = { ...(user.customClaims ?? {}) };
  if (makeAdmin) {
    claims.role = "super_admin";
  } else if (claims.role === "super_admin") {
    // Back to vendor if they own a vendor, otherwise plain customer.
    if (claims.vendorId) claims.role = "vendor";
    else delete claims.role;
  }
  await auth.setCustomUserClaims(uid, claims);
  await auth.revokeRefreshTokens(uid);
  await userDoc.ref.update({ role: (claims.role as string) ?? "customer" });
  return { ok: true };
});

/// Admin-only: suspend/restore a vendor business. A suspended vendor's
/// products stay visible but placeOrder refuses new orders for them, and
/// bulk-* callables refuse the vendor (requireBulkVendor checks status).
export const setVendorStatus = onCall<{ vendorId: string; status: "approved" | "suspended" }>(
  { region: "us-central1" },
  async (request) => {
    requireRole(request, ["super_admin"]);
    const vendorId = cleanDocId(request.data?.vendorId, "vendorId");
    const status = cleanEnum(request.data?.status, ["approved", "suspended"] as const, "status");
    const ref = db.collection("vendors").doc(vendorId);
    if (!(await ref.get()).exists) throw new HttpsError("not-found", "Vendor not found.");
    await ref.update({ status, updatedAt: FieldValue.serverTimestamp() });
    return { ok: true };
  },
);
