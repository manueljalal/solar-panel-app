"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.closePost = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const sanitize_1 = require("../shared/validation/sanitize");
const shared_1 = require("./shared");
/// Owner-only. Takes one of the caller's posts off the marketplace
/// (listing sold out / request filled). Soft close — the doc is kept.
exports.closePost = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    const me = await (0, shared_1.requireBulkVendor)(request);
    const kind = (0, sanitize_1.cleanEnum)(request.data?.kind, ["listing", "request"], "kind");
    const id = (0, sanitize_1.cleanDocId)(request.data?.id, "id");
    const ref = firebase_1.db.collection(kind === "listing" ? "bulkListings" : "bulkRequests").doc(id);
    const snap = await ref.get();
    if (!snap.exists || snap.data()?.vendorId !== me.vendorId) {
        throw new https_1.HttpsError("not-found", "Post not found.");
    }
    await ref.update({ status: "closed", closedAt: firestore_1.FieldValue.serverTimestamp() });
    return { ok: true };
});
