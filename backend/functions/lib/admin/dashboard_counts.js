"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.dashboardCounts = void 0;
const https_1 = require("firebase-functions/v2/https");
const firebase_1 = require("../shared/firebase");
const require_role_1 = require("../shared/auth/require_role");
/// Admin-only. Dashboard tile numbers via count() aggregations — each is
/// billed as one read per 1,000 matches and returns no documents, unlike
/// listing every application just to take .length (which also capped the
/// numbers at the list limit of 100).
exports.dashboardCounts = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    (0, require_role_1.requireRole)(request, ["super_admin"]);
    const applications = firebase_1.db.collection("vendorApplications");
    const [pending, approved, rejected, newOrders] = await Promise.all([
        applications.where("status", "==", "pending").count().get(),
        applications.where("status", "==", "approved").count().get(),
        applications.where("status", "==", "rejected").count().get(),
        firebase_1.db.collection("orders").where("status", "==", "placed").count().get(),
    ]);
    return {
        pending: pending.data().count,
        approved: approved.data().count,
        rejected: rejected.data().count,
        newOrders: newOrders.data().count,
    };
});
