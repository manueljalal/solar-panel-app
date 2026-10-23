"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateOrderStatus = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const require_role_1 = require("../shared/auth/require_role");
const order_status_1 = require("../shared/orders/order_status");
const sanitize_1 = require("../shared/validation/sanitize");
/// Admin-only. Moves an order along placed → confirmed → shipped →
/// delivered, or cancels it. Marking an order delivered is also when each
/// product's `sold` counter goes up — counting at placement would inflate
/// "best sellers" with orders that later get cancelled.
exports.updateOrderStatus = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    const { uid } = (0, require_role_1.requireRole)(request, ["super_admin"]);
    const orderId = (0, sanitize_1.cleanDocId)(request.data?.orderId, "orderId");
    const status = (0, sanitize_1.cleanEnum)(request.data?.status, order_status_1.ORDER_STATUSES, "status");
    const orderRef = firebase_1.db.collection("orders").doc(orderId);
    await firebase_1.db.runTransaction(async (tx) => {
        const snap = await tx.get(orderRef);
        const data = snap.data();
        if (!snap.exists || !data) {
            throw new https_1.HttpsError("not-found", "Order not found.");
        }
        (0, order_status_1.assertTransition)(data.status, status);
        // Transactions need every read before the first write, so the
        // product lookups happen up front. A product deleted since the order
        // was placed is skipped rather than failing the status change.
        // One batched read (getAll) rather than a round trip per line.
        const soldUpdates = [];
        if (status === "delivered") {
            const lines = (data.items ?? []).filter((item) => !!item.productId && !!item.quantity);
            if (lines.length > 0) {
                const refs = lines.map((item) => firebase_1.db.collection("products").doc(item.productId));
                const snaps = await tx.getAll(...refs);
                snaps.forEach((snap, i) => {
                    if (snap.exists)
                        soldUpdates.push({ ref: refs[i], quantity: lines[i].quantity });
                });
            }
        }
        tx.update(orderRef, {
            status,
            statusHistory: firestore_1.FieldValue.arrayUnion({ status, at: new Date(), by: uid }),
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        });
        for (const { ref, quantity } of soldUpdates) {
            tx.update(ref, { sold: firestore_1.FieldValue.increment(quantity) });
        }
    });
    return { ok: true };
});
