import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { requireRole } from "../shared/auth/require_role";
import { ORDER_STATUSES } from "../shared/orders/status";
import { readSettings, settingsRef } from "../shared/orders/settings";
import { cleanText } from "../shared/validation/sanitize";

const count = async (q: FirebaseFirestore.Query) => (await q.count().get()).data().count;

/// Admin-only: platform numbers for the dashboard and Analytics page.
/// Counts use aggregation queries (billed per 1000 index entries, not per
/// document). Revenue is summed over the last 30 days of completed orders
/// only, per currency, so it stays a bounded read.
export const getAnalytics = onCall({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);

  const orders = db.collection("orders");
  const [users, vendors, products, openDisputes, pendingApplications, pendingQuotes, ...statusCounts] = await Promise.all([
    count(db.collection("users")),
    count(db.collection("vendors")),
    count(db.collection("products")),
    count(db.collection("disputes").where("status", "==", "open")),
    count(db.collection("vendorApplications").where("status", "==", "pending")),
    count(db.collection("quoteRequests").where("status", "==", "submitted")),
    ...ORDER_STATUSES.map((s) => count(orders.where("status", "==", s))),
  ]);

  const since = Timestamp.fromMillis(Date.now() - 30 * 24 * 60 * 60 * 1000);
  const recent = await orders.where("createdAt", ">=", since).orderBy("createdAt", "desc").limit(2000).get();
  const revenue30d: Record<string, number> = { USD: 0, IQD: 0 };
  const ordersByDay: Record<string, number> = {};
  for (const doc of recent.docs) {
    const o = doc.data();
    const day = (o.createdAt as Timestamp | undefined)?.toDate().toISOString().slice(0, 10);
    if (day) ordersByDay[day] = (ordersByDay[day] ?? 0) + 1;
    if (o.status === "installed_verified" && typeof o.total === "number") {
      revenue30d[o.currency] = Math.round(((revenue30d[o.currency] ?? 0) + o.total) * 100) / 100;
    }
  }

  return {
    users,
    vendors,
    products,
    openDisputes,
    pendingApplications,
    pendingQuotes,
    ordersByStatus: Object.fromEntries(ORDER_STATUSES.map((s, i) => [s, statusCounts[i]])),
    revenue30d,
    ordersByDay,
    recentOrdersTruncated: recent.size >= 2000,
  };
});

export const getSettings = onCall({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);
  return readSettings();
});

interface UpdateSettingsInput {
  ordersEnabled?: boolean;
  deliveryFee?: { USD?: number; IQD?: number };
  supportPhone?: string;
  supportEmail?: string;
}

function cleanFee(value: unknown, field: string): number {
  if (typeof value !== "number" || !Number.isFinite(value) || value < 0 || value > 10_000_000) {
    throw new HttpsError("invalid-argument", `${field} must be zero or a positive number.`);
  }
  return Math.round(value * 100) / 100;
}

/// Admin-only: edit settings/platform (see shared/orders/settings.ts).
export const updateSettings = onCall<UpdateSettingsInput>({ region: "us-central1" }, async (request) => {
  const { uid } = requireRole(request, ["super_admin"]);
  const input = request.data ?? {};
  const current = await readSettings();
  const next = {
    ordersEnabled: input.ordersEnabled === undefined ? current.ordersEnabled : input.ordersEnabled === true,
    deliveryFee: {
      USD: input.deliveryFee?.USD === undefined ? current.deliveryFee.USD : cleanFee(input.deliveryFee.USD, "USD delivery fee"),
      IQD: input.deliveryFee?.IQD === undefined ? current.deliveryFee.IQD : cleanFee(input.deliveryFee.IQD, "IQD delivery fee"),
    },
    supportPhone: input.supportPhone === undefined ? current.supportPhone : cleanText(input.supportPhone, "Support phone", { max: 20 }),
    supportEmail: input.supportEmail === undefined ? current.supportEmail : cleanText(input.supportEmail, "Support email", { max: 254 }),
  };
  await settingsRef().set({ ...next, updatedAt: FieldValue.serverTimestamp(), updatedBy: uid });
  return next;
});
