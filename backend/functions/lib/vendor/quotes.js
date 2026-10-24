"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateQuoteRequest = exports.listQuoteRequests = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const require_role_1 = require("../shared/auth/require_role");
const sanitize_1 = require("../shared/validation/sanitize");
const quotes_1 = require("../shared/quotes");
/// Quote requests shoppers sent for this vendor's products, newest first.
exports.listQuoteRequests = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    const { vendorId } = (0, require_role_1.requireVendor)(request);
    const snap = await firebase_1.db.collection("quoteRequests").where("vendorId", "==", vendorId).limit(500).get();
    const requests = snap.docs.map(quotes_1.serializeQuote).sort((a, b) => (b.createdAt ?? 0) - (a.createdAt ?? 0));
    return { requests };
});
/// Vendor marks a request as contacted / closed.
exports.updateQuoteRequest = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    const { vendorId } = (0, require_role_1.requireVendor)(request);
    const id = (0, sanitize_1.cleanDocId)(request.data?.id, "id");
    const status = (0, sanitize_1.cleanEnum)(request.data?.status, quotes_1.QUOTE_STATUSES, "status");
    const ref = firebase_1.db.collection("quoteRequests").doc(id);
    const snap = await ref.get();
    if (!snap.exists || snap.data()?.vendorId !== vendorId)
        throw new https_1.HttpsError("not-found", "Request not found.");
    await ref.update({ status, updatedAt: firestore_1.FieldValue.serverTimestamp() });
    return { ok: true };
});
