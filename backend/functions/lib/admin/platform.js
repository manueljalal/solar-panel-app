"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.listQuoteRequests = exports.closeBulkPost = exports.listBulkPosts = exports.removeProduct = exports.listProducts = exports.listUsers = exports.getStats = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const require_role_1 = require("../shared/auth/require_role");
const sanitize_1 = require("../shared/validation/sanitize");
const quotes_1 = require("../shared/quotes");
const millis = (t) => (t instanceof firestore_1.Timestamp ? t.toMillis() : null);
async function count(q) {
    return (await q.count().get()).data().count;
}
/// Admin dashboard numbers. count() aggregations on single-field equality
/// filters, so no composite indexes and no document reads.
exports.getStats = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    (0, require_role_1.requireRole)(request, ["super_admin"]);
    const orders = firebase_1.db.collection("orders");
    const [users, vendors, products, pendingApplications, placed, confirmed, outForDelivery, delivered, cancelled, newQuotes, bulkListings, bulkRequests,] = await Promise.all([
        count(firebase_1.db.collection("users")),
        count(firebase_1.db.collection("vendors").where("status", "==", "approved")),
        count(firebase_1.db.collection("products")),
        count(firebase_1.db.collection("vendorApplications").where("status", "==", "pending")),
        count(orders.where("status", "==", "placed")),
        count(orders.where("status", "==", "confirmed")),
        count(orders.where("status", "==", "out_for_delivery")),
        count(orders.where("status", "==", "delivered")),
        count(orders.where("status", "==", "cancelled")),
        count(firebase_1.db.collection("quoteRequests").where("status", "==", "new")),
        count(firebase_1.db.collection("bulkListings").where("status", "==", "active")),
        count(firebase_1.db.collection("bulkRequests").where("status", "==", "open")),
    ]);
    return {
        users, vendors, products, pendingApplications,
        orders: { placed, confirmed, outForDelivery, delivered, cancelled },
        newQuotes, bulkListings, bulkRequests,
    };
});
/// Everyone with an account, newest first. Never returns password hashes
/// or device ids. Role: vendor if the account owns a vendor profile.
exports.listUsers = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    (0, require_role_1.requireRole)(request, ["super_admin"]);
    const [usersSnap, vendorsSnap] = await Promise.all([
        firebase_1.db.collection("users").orderBy("createdAt", "desc").limit(500).get(),
        firebase_1.db.collection("vendors").get(),
    ]);
    const vendorByOwner = new Map(vendorsSnap.docs.map((v) => [v.data().ownerUid, v.data().businessName]));
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
exports.listProducts = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    (0, require_role_1.requireRole)(request, ["super_admin"]);
    const [productsSnap, vendorsSnap] = await Promise.all([
        firebase_1.db.collection("products").limit(1000).get(),
        firebase_1.db.collection("vendors").get(),
    ]);
    const vendorName = new Map(vendorsSnap.docs.map((v) => [v.id, v.data().businessName]));
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
exports.removeProduct = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    (0, require_role_1.requireRole)(request, ["super_admin"]);
    const productId = (0, sanitize_1.cleanDocId)(request.data?.productId, "productId");
    const ref = firebase_1.db.collection("products").doc(productId);
    if (!(await ref.get()).exists)
        throw new https_1.HttpsError("not-found", "Product not found.");
    await ref.delete();
    return { ok: true };
});
/// All B2B posts of one kind (any status), newest first.
exports.listBulkPosts = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    (0, require_role_1.requireRole)(request, ["super_admin"]);
    const kind = (0, sanitize_1.cleanEnum)(request.data?.kind, ["listing", "request"], "kind");
    const snap = await firebase_1.db
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
exports.closeBulkPost = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    (0, require_role_1.requireRole)(request, ["super_admin"]);
    const kind = (0, sanitize_1.cleanEnum)(request.data?.kind, ["listing", "request"], "kind");
    const id = (0, sanitize_1.cleanDocId)(request.data?.id, "id");
    const ref = firebase_1.db.collection(kind === "listing" ? "bulkListings" : "bulkRequests").doc(id);
    if (!(await ref.get()).exists)
        throw new https_1.HttpsError("not-found", "Post not found.");
    await ref.update({ status: "closed", closedAt: firestore_1.FieldValue.serverTimestamp(), closedBy: "admin" });
    return { ok: true };
});
/// All quote requests across vendors, newest first.
exports.listQuoteRequests = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    (0, require_role_1.requireRole)(request, ["super_admin"]);
    const snap = await firebase_1.db.collection("quoteRequests").orderBy("createdAt", "desc").limit(500).get();
    return { requests: snap.docs.map(quotes_1.serializeQuote) };
});
