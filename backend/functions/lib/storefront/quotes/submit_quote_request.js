"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.submitQuoteRequest = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../../shared/firebase");
const sanitize_1 = require("../../shared/validation/sanitize");
/// A shopper asks a vendor for a price on one product (bulk quantity,
/// installation, site address...). Needs a real account: the vendor answers
/// by calling the verified phone. Product name and vendor are read from the
/// product doc, never trusted from the client, so the request lands in that
/// vendor's inbox (vendor-listQuoteRequests).
exports.submitQuoteRequest = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    const auth = request.auth;
    if (!auth)
        throw new https_1.HttpsError("unauthenticated", "Sign in required.");
    if (auth.token.firebase?.sign_in_provider === "anonymous") {
        throw new https_1.HttpsError("failed-precondition", "Create an account to request a quote.");
    }
    const productId = (0, sanitize_1.cleanDocId)(request.data?.productId, "productId");
    const note = (0, sanitize_1.cleanText)(request.data?.note, "note", { max: 1000, multiline: true });
    const product = (await firebase_1.db.collection("products").doc(productId).get()).data();
    if (!product?.vendorId)
        throw new https_1.HttpsError("not-found", "This product is no longer available.");
    const [vendor, user] = await Promise.all([
        firebase_1.db.collection("vendors").doc(product.vendorId).get(),
        firebase_1.db.collection("users").doc(auth.uid).get(),
    ]);
    const ref = firebase_1.db.collection("quoteRequests").doc();
    await ref.set({
        uid: auth.uid,
        customerName: user.data()?.name ?? "",
        customerPhone: user.data()?.phone ?? "",
        productId,
        productTitle: product.name ?? "",
        productImageUrl: product.imageUrl ?? "",
        vendorId: product.vendorId,
        vendorName: vendor.data()?.businessName ?? "",
        note,
        status: "new",
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return { requestId: ref.id };
});
