"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateOrderStatus = exports.listOrders = void 0;
const https_1 = require("firebase-functions/v2/https");
const firebase_1 = require("../../shared/firebase");
const require_role_1 = require("../../shared/auth/require_role");
const sanitize_1 = require("../../shared/validation/sanitize");
const orders_1 = require("../../shared/orders");
/// The calling vendor's orders, newest first, optionally one status.
exports.listOrders = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    const { vendorId } = (0, require_role_1.requireVendor)(request);
    const status = request.data?.status ? (0, sanitize_1.cleanEnum)(request.data.status, orders_1.ORDER_STATUSES, "status") : null;
    const snap = await firebase_1.db.collection("orders").where("vendorId", "==", vendorId).limit(500).get();
    const orders = snap.docs
        .map((d) => (0, orders_1.serializeOrder)(d))
        .filter((o) => !status || o.status === status)
        .sort((a, b) => (b.createdAt ?? 0) - (a.createdAt ?? 0));
    return { orders };
});
/// Vendor moves one of its orders along: confirm, dispatch, deliver, or
/// cancel (with a reason) before it's dispatched.
exports.updateOrderStatus = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    const { uid, vendorId } = (0, require_role_1.requireVendor)(request);
    const orderId = (0, sanitize_1.cleanDocId)(request.data?.orderId, "orderId");
    const status = (0, sanitize_1.cleanEnum)(request.data?.status, orders_1.ORDER_STATUSES, "status");
    const reason = (0, sanitize_1.cleanText)(request.data?.reason, "reason", { max: 300 });
    await (0, orders_1.transitionOrder)(orderId, status, { role: "vendor", uid, vendorId }, reason);
    return { ok: true };
});
