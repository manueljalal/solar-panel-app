"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.cancelOrder = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../../shared/firebase");
const sanitize_1 = require("../../shared/validation/sanitize");
/// The customer who placed an order can cancel it until a vendor/admin has
/// confirmed it — after that, cancelling goes through support (admin).
/// Runs in a transaction so a cancel can't race an admin confirming the
/// same order.
exports.cancelOrder = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Sign in required.");
    }
    const uid = request.auth.uid;
    const orderId = (0, sanitize_1.cleanDocId)(request.data?.orderId, "orderId");
    const orderRef = firebase_1.db.collection("orders").doc(orderId);
    await firebase_1.db.runTransaction(async (tx) => {
        const snap = await tx.get(orderRef);
        const data = snap.data();
        // Same error for "doesn't exist" and "isn't yours" — don't confirm
        // that someone else's order id is valid.
        if (!snap.exists || !data || data.uid !== uid) {
            throw new https_1.HttpsError("not-found", "Order not found.");
        }
        if (data.status !== "placed") {
            throw new https_1.HttpsError("failed-precondition", "This order has already been confirmed — contact support to cancel it.");
        }
        tx.update(orderRef, {
            status: "cancelled",
            statusHistory: firestore_1.FieldValue.arrayUnion({ status: "cancelled", at: new Date(), by: "customer" }),
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        });
    });
    return { ok: true };
});
