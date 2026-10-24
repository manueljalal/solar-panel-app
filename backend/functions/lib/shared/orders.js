"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ORDER_STATUSES = void 0;
exports.serializeOrder = serializeOrder;
exports.transitionOrder = transitionOrder;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("./firebase");
/// Order lifecycle (cash on delivery):
///   placed -> confirmed -> out_for_delivery -> delivered
/// and cancelled from placed (customer, vendor or admin) or confirmed
/// (vendor or admin). Delivered and cancelled are final.
exports.ORDER_STATUSES = ["placed", "confirmed", "out_for_delivery", "delivered", "cancelled"];
const NEXT = {
    placed: ["confirmed", "cancelled"],
    confirmed: ["out_for_delivery", "cancelled"],
    out_for_delivery: ["delivered"],
    delivered: [],
    cancelled: [],
};
/// Firestore order doc -> JSON for the callable response (timestamps as
/// epoch millis; the customer's internal uid is not exposed to vendors).
function serializeOrder(snap, opts = {}) {
    const d = snap.data() ?? {};
    const millis = (t) => (t instanceof firestore_1.Timestamp ? t.toMillis() : null);
    return {
        id: snap.id,
        ...(opts.includeUid ? { uid: d.uid } : {}),
        vendorId: d.vendorId,
        vendorName: d.vendorName ?? "",
        customerName: d.customerName ?? "",
        customerPhone: d.customerPhone ?? "",
        items: (d.items ?? []),
        totals: (d.totals ?? {}),
        paymentMethod: d.paymentMethod ?? "cod",
        address: d.address ?? "",
        location: d.location ?? null,
        note: d.note ?? "",
        status: d.status,
        cancelReason: d.cancelReason ?? null,
        statusHistory: (d.statusHistory ?? []).map((h) => ({
            status: h.status,
            at: millis(h.at),
            by: h.by,
        })),
        createdAt: millis(d.createdAt),
        updatedAt: millis(d.updatedAt),
    };
}
/// Moves an order to [next] if [actor] may, inside a transaction so two
/// people acting at once can't skip or repeat a step. Delivering an order
/// adds its quantities to each product's `sold` counter.
async function transitionOrder(orderId, next, actor, reason) {
    const ref = firebase_1.db.collection("orders").doc(orderId);
    await firebase_1.db.runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        const order = snap.data();
        if (!snap.exists || !order)
            throw new https_1.HttpsError("not-found", "Order not found.");
        if (actor.role === "customer" && order.uid !== actor.uid)
            throw new https_1.HttpsError("not-found", "Order not found.");
        if (actor.role === "vendor" && order.vendorId !== actor.vendorId)
            throw new https_1.HttpsError("not-found", "Order not found.");
        const current = order.status;
        if (!NEXT[current].includes(next)) {
            throw new https_1.HttpsError("failed-precondition", `An order that is '${current}' can't become '${next}'.`);
        }
        // Customers may only cancel, and only before the vendor confirms.
        if (actor.role === "customer" && !(next === "cancelled" && current === "placed")) {
            throw new https_1.HttpsError("permission-denied", "This order can no longer be cancelled from the app.");
        }
        const update = {
            status: next,
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
            statusHistory: firestore_1.FieldValue.arrayUnion({ status: next, at: firestore_1.Timestamp.now(), by: actor.role }),
        };
        if (next === "cancelled")
            update.cancelReason = reason || null;
        if (next === "delivered") {
            update.deliveredAt = firestore_1.FieldValue.serverTimestamp();
            for (const item of (order.items ?? [])) {
                tx.update(firebase_1.db.collection("products").doc(item.productId), { sold: firestore_1.FieldValue.increment(item.qty) });
            }
        }
        tx.update(ref, update);
    });
}
