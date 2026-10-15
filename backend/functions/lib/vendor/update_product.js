"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateProduct = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const require_role_1 = require("../shared/auth/require_role");
const store_image_1 = require("../shared/images/store_image");
const sanitize_1 = require("../shared/validation/sanitize");
const EDITABLE_FIELDS = new Set([
    "category",
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
    const clean = {};
    for (const [key, value] of Object.entries(patch)) {
        switch (key) {
            case "category": {
                const category = (0, sanitize_1.cleanDocId)(value, "category");
                if (!(await firebase_1.db.collection("categories").doc(category).get()).exists) {
                    throw new https_1.HttpsError("invalid-argument", "Choose a category from the list.");
                }
                clean.category = category;
                break;
            }
            case "brand":
                clean.brand = (0, sanitize_1.cleanText)(value, "brand", { max: 80, min: 1 });
                break;
            case "name": {
                const name = (0, sanitize_1.cleanLocalized)(value, "Product name", { max: 120 });
                clean.name = name.en;
                clean.nameI18n = name;
                break;
            }
            case "spec":
                clean.spec = (0, sanitize_1.cleanText)(value, "spec", { max: 120 });
                break;
            case "description": {
                const d = (0, sanitize_1.cleanLocalized)(value, "Description", { max: 2000, multiline: true, optional: true });
                clean.description = d?.en ?? null;
                clean.descriptionI18n = d;
                break;
            }
            case "warranty": {
                const w = (0, sanitize_1.cleanLocalized)(value, "Warranty", { max: 120, optional: true });
                clean.warranty = w?.en ?? null;
                clean.warrantyI18n = w;
                break;
            }
            case "price":
                clean.price = (0, sanitize_1.cleanPrice)(value);
                break;
            case "currency":
                clean.currency = (0, sanitize_1.cleanEnum)(value, ["USD", "IQD"], "currency");
                break;
            case "wattage":
                if (value !== null && (!Number.isInteger(value) || value <= 0 || value > 1000000)) {
                    throw new https_1.HttpsError("invalid-argument", "wattage must be a positive whole number.");
                }
                clean.wattage = value;
                break;
            case "inStock":
                if (typeof value !== "boolean")
                    throw new https_1.HttpsError("invalid-argument", "inStock must be true or false.");
                clean.inStock = value;
                break;
            case "imageUrl":
                if (!(0, store_image_1.isOwnedImageUrl)(value, `productImages/${vendorId}`)) {
                    throw new https_1.HttpsError("invalid-argument", "Upload a product image first.");
                }
                clean.imageUrl = value;
                break;
        }
    }
    const productRef = firebase_1.db.collection("products").doc((0, sanitize_1.cleanDocId)(productId, "productId"));
    const snap = await productRef.get();
    if (!snap.exists) {
        throw new https_1.HttpsError("not-found", "Product not found.");
    }
    if (snap.data().vendorId !== vendorId) {
        throw new https_1.HttpsError("permission-denied", "You don't own this product.");
    }
    await productRef.update({ ...clean, updatedAt: firestore_1.FieldValue.serverTimestamp() });
    return { ok: true };
});
