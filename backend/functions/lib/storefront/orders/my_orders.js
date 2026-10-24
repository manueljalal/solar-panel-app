"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.cancelMyOrder = exports.listMyOrders = void 0;
const https_1 = require("firebase-functions/v2/https");
const firebase_1 = require("../../shared/firebase");
const sanitize_1 = require("../../shared/validation/sanitize");
const orders_1 = require("../../shared/orders");
/// The caller's own orders, newest first. Equality-only query + in-memory
/// sort, so no composite index is needed.
exports.listMyOrders = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError("unauthenticated", "Sign in required.");
    const snap = await firebase_1.db.collection("orders").where("uid", "==", request.auth.uid).limit(200).get();
    const orders = snap.docs.map((d) => (0, orders_1.serializeOrder)(d)).sort((a, b) => (b.createdAt ?? 0) - (a.createdAt ?? 0));
    return { orders };
});
/// Customer cancels their own order — only while it is still 'placed'.
exports.cancelMyOrder = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError("unauthenticated", "Sign in required.");
    const orderId = (0, sanitize_1.cleanDocId)(request.data?.orderId, "orderId");
    const reason = (0, sanitize_1.cleanText)(request.data?.reason, "reason", { max: 300 });
    await (0, orders_1.transitionOrder)(orderId, "cancelled", { role: "customer", uid: request.auth.uid }, reason);
    return { ok: true };
});
