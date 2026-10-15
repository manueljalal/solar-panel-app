"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getMyApplication = void 0;
const https_1 = require("firebase-functions/v2/https");
const firebase_1 = require("../shared/firebase");
/// Signed-in callers only. Returns the caller's most recent vendor
/// application (status + business name) or null if they never applied —
/// the mobile apply screen uses it to show "pending" / "approved" instead
/// of a blank form. Sorted in memory (a few rows per user) so no
/// uid+createdAt composite index is needed.
exports.getMyApplication = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Sign in required.");
    }
    const snap = await firebase_1.db.collection("vendorApplications").where("uid", "==", request.auth.uid).limit(20).get();
    if (snap.empty)
        return { application: null };
    const newest = snap.docs
        .map((d) => d.data())
        .sort((a, b) => (b.createdAt?.toMillis?.() ?? 0) - (a.createdAt?.toMillis?.() ?? 0))[0];
    return {
        application: {
            status: newest.status,
            businessName: newest.businessName ?? "",
        },
    };
});
