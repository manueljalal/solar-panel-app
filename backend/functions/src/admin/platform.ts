import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { requireRole } from "../shared/auth/require_role";
import { cleanDocId, cleanEnum } from "../shared/validation/sanitize";
import { serializeQuote } from "../shared/quotes";

const millis = (t: unknown) => (t instanceof Timestamp ? t.toMillis() : null);

async function count(q: FirebaseFirestore.Query): Promise<number> {
  return (await q.count().get()).data().count;
}

/// Admin dashboard numbers. count() aggregations on single-field equality
/// filters, so no composite indexes and no document reads.
export const getStats = onCall({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);
  const orders = db.collection("orders");
  const [
    users, vendors, products, pendingApplications,
    placed, confirmed, outForDelivery, delivered, cancelled,
    newQuotes, bulkListings, bulkRequests, newServiceRequests,
  ] = await Promise.all([
    count(db.collection("users")),
    count(db.collection("vendors").where("status", "==", "approved")),
    count(db.collection("products")),
    count(db.collection("vendorApplications").where("status", "==", "pending")),
    count(orders.where("status", "==", "placed")),
    count(orders.where("status", "==", "confirmed")),
    count(orders.where("status", "==", "out_for_delivery")),
    count(orders.where("status", "==", "delivered")),
    count(orders.where("status", "==", "cancelled")),
    count(db.collection("quoteRequests").where("status", "==", "new")),
    count(db.collection("bulkListings").where("status", "==", "active")),
    count(db.collection("bulkRequests").where("status", "==", "open")),
    count(db.collection("serviceRequests").where("status", "==", "new")),
  ]);
  return {
    users, vendors, products, pendingApplications,
    orders: { placed, confirmed, outForDelivery, delivered, cancelled },
    newQuotes, bulkListings, bulkRequests, newServiceRequests,
  };
});

/// Everyone with an account, newest first. Never returns password hashes
/// or device ids. Role: vendor if the account owns a vendor profile.
export const listUsers = onCall({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);
  const [usersSnap, vendorsSnap] = await Promise.all([
    db.collection("users").orderBy("createdAt", "desc").limit(500).get(),
    db.collection("vendors").get(),
  ]);
  const vendorByOwner = new Map(vendorsSnap.docs.map((v) => [v.data().ownerUid as string, v.data().businessName as string]));
  const users = usersSnap.docs.map((d) => {
    const u = d.data();
    return {
      id: d.id,
      name: u.name ?? "",
      username: u.username ?? "",
      phone: u.phone ?? "",
      email: u.email ?? "",
      role: u.role === "super_admin" ? "super_admin" : vendorByOwner.has(d.id) ? "vendor" : "customer",
      vendorName: vendorByOwner.get(d.id) ?? null,
      createdAt: millis(u.createdAt),
      lastSignInAt: millis(u.lastSignInAt),
    };
  });
  return { users };
});

/// Every product with its vendor's name, newest first — for moderation.
export const listProducts = onCall({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);
  const [productsSnap, vendorsSnap] = await Promise.all([
    db.collection("products").limit(1000).get(),
    db.collection("vendors").get(),
  ]);
  const vendorName = new Map(vendorsSnap.docs.map((v) => [v.id, v.data().businessName as string]));
  const products = productsSnap.docs
    .map((d) => {
      const p = d.data();
      return {
        id: d.id,
        name: p.name ?? "",
        brand: p.brand ?? "",
        spec: p.spec ?? "",
        category: p.category ?? "",
        price: p.price ?? 0,
        currency: p.currency ?? "USD",
        imageUrl: p.imageUrl ?? "",
        inStock: p.inStock !== false,
        sold: p.sold ?? 0,
        vendorId: p.vendorId ?? null,
        vendorName: vendorName.get(p.vendorId) ?? "Unknown vendor",
        createdAt: millis(p.createdAt),
      };
    })
    .sort((a, b) => (b.createdAt ?? 0) - (a.createdAt ?? 0));
  return { products };
});

/// Takes a product off the marketplace (policy violation, duplicate...).
export const removeProduct = onCall<{ productId: string }>({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);
  const productId = cleanDocId(request.data?.productId, "productId");
  const ref = db.collection("products").doc(productId);
  if (!(await ref.get()).exists) throw new HttpsError("not-found", "Product not found.");
  await ref.delete();
  return { ok: true };
});

/// All B2B posts of one kind (any status), newest first.
export const listBulkPosts = onCall<{ kind: string }>({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);
  const kind = cleanEnum(request.data?.kind, ["listing", "request"] as const, "kind");
  const snap = await db
    .collection(kind === "listing" ? "bulkListings" : "bulkRequests")
    .orderBy("createdAt", "desc")
    .limit(500)
    .get();
  const posts = snap.docs.map((d) => {
    const p = d.data();
    return {
      id: d.id,
      title: p.title ?? "",
      businessName: p.businessName ?? "",
      country: p.country ?? "IQ",
      phone: p.phone ?? "",
      status: p.status ?? "",
      unit: p.unit ?? "",
      quantity: p.quantity ?? null,
      tiers: p.tiers ?? null,
      targetPriceUsd: p.targetPriceUsd ?? null,
      imageUrl: p.imageUrl ?? "",
      createdAt: millis(p.createdAt),
    };
  });
  return { posts };
});

/// Admin takes a B2B post down (closes it, keeping the record).
export const closeBulkPost = onCall<{ kind: string; id: string }>({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);
  const kind = cleanEnum(request.data?.kind, ["listing", "request"] as const, "kind");
  const id = cleanDocId(request.data?.id, "id");
  const ref = db.collection(kind === "listing" ? "bulkListings" : "bulkRequests").doc(id);
  if (!(await ref.get()).exists) throw new HttpsError("not-found", "Post not found.");
  await ref.update({ status: "closed", closedAt: FieldValue.serverTimestamp(), closedBy: "admin" });
  return { ok: true };
});

/// All quote requests across vendors, newest first.
export const listQuoteRequests = onCall({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);
  const snap = await db.collection("quoteRequests").orderBy("createdAt", "desc").limit(500).get();
  return { requests: snap.docs.map(serializeQuote) };
});
