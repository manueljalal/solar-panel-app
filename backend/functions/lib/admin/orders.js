"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateOrderStatus = exports.listOrders = void 0;
const https_1 = require("firebase-functions/v2/https");
const firebase_1 = require("../shared/firebase");
const require_role_1 = require("../shared/auth/require_role");
const sanitize_1 = require("../shared/validation/sanitize");
const orders_1 = require("../shared/orders");
/// Admin: newest orders across all vendors (single-field createdAt order,
/// no composite index), optionally filtered by status.
exports.listOrders = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    (0, require_role_1.requireRole)(request, ["super_admin"]);
    const status = request.data?.status ? (0, sanitize_1.cleanEnum)(request.data.status, orders_1.ORDER_STATUSES, "status") : null;
    const snap = await firebase_1.db.collection("orders").orderBy("createdAt", "desc").limit(500).get();
    const orders = snap.docs.map((d) => (0, orders_1.serializeOrder)(d, { includeUid: true })).filter((o) => !status || o.status === status);
    return { orders };
});
/// Admin override for stuck orders — same transition rules as vendors.
exports.updateOrderStatus = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    const { uid } = (0, require_role_1.requireRole)(request, ["super_admin"]);
    const orderId = (0, sanitize_1.cleanDocId)(request.data?.orderId, "orderId");
    const status = (0, sanitize_1.cleanEnum)(request.data?.status, orders_1.ORDER_STATUSES, "status");
    const reason = (0, sanitize_1.cleanText)(request.data?.reason, "reason", { max: 300 });
    await (0, orders_1.transitionOrder)(orderId, status, { role: "super_admin", uid }, reason);
    return { ok: true };
});
