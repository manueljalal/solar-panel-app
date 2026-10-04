"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteProduct = void 0;
const https_1 = require("firebase-functions/v2/https");
const firebase_1 = require("../shared/firebase");
const require_role_1 = require("../shared/auth/require_role");
exports.deleteProduct = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    const { vendorId } = (0, require_role_1.requireVendor)(request);
    const { productId } = request.data;
    if (!productId) {
        throw new https_1.HttpsError("invalid-argument", "productId is required.");
    }
    const productRef = firebase_1.db.collection("products").doc(productId);
    const snap = await productRef.get();
    if (!snap.exists) {
        throw new https_1.HttpsError("not-found", "Product not found.");
    }
    if (snap.data().vendorId !== vendorId) {
        throw new https_1.HttpsError("permission-denied", "You don't own this product.");
    }
    await productRef.delete();
    return { ok: true };
});
