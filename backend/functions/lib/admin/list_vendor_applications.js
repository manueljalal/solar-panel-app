"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.listVendorApplications = void 0;
const https_1 = require("firebase-functions/v2/https");
const firebase_1 = require("../shared/firebase");
const require_role_1 = require("../shared/auth/require_role");
/// Admin-only. Firestore rules deny direct client reads of
/// vendorApplications outside the submitter's own doc, so the admin
/// panel goes through this callable rather than a client-side query.
exports.listVendorApplications = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    (0, require_role_1.requireRole)(request, ["super_admin"]);
    const status = request.data?.status ?? "pending";
    const snap = await firebase_1.db
        .collection("vendorApplications")
        .where("status", "==", status)
        .orderBy("createdAt", "desc")
        .limit(100)
        .get();
    return {
        applications: snap.docs.map((d) => ({ id: d.id, ...d.data() })),
    };
});
