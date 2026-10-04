"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateProduct = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const require_role_1 = require("../shared/auth/require_role");
const EDITABLE_FIELDS = new Set([
    "brand",
    "name",
    "spec",
    "wattage",
    "price",
    "currency",
    "imageUrl",
    "description",
    "warranty",
    "inStock",
]);
/// Vendor-only, and only on products that vendor owns — this server-side
/// ownership check is why product writes go through a callable instead of
/// Firestore rules alone (a rule would need a get() per write to check
/// vendorId).
exports.updateProduct = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    const { vendorId } = (0, require_role_1.requireVendor)(request);
    const { productId, patch } = request.data;
    if (!productId || !patch || Object.keys(patch).length === 0) {
        throw new https_1.HttpsError("invalid-argument", "productId and a non-empty patch are required.");
    }
    const invalidKeys = Object.keys(patch).filter((k) => !EDITABLE_FIELDS.has(k));
    if (invalidKeys.length > 0) {
        throw new https_1.HttpsError("invalid-argument", `Not editable: ${invalidKeys.join(", ")}`);
    }
    const productRef = firebase_1.db.collection("products").doc(productId);
    const snap = await productRef.get();
    if (!snap.exists) {
        throw new https_1.HttpsError("not-found", "Product not found.");
    }
    if (snap.data().vendorId !== vendorId) {
        throw new https_1.HttpsError("permission-denied", "You don't own this product.");
    }
    await productRef.update({ ...patch, updatedAt: firestore_1.FieldValue.serverTimestamp() });
    return { ok: true };
});
