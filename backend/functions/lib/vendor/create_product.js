"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createProduct = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const require_role_1 = require("../shared/auth/require_role");
const store_image_1 = require("../shared/images/store_image");
const sanitize_1 = require("../shared/validation/sanitize");
/// Vendor-only. This is the actual "upload a product" operation — the
/// piece that was completely missing before: every product in Firestore
/// until now came from a one-off seed script, not from a real vendor.
exports.createProduct = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    const { vendorId } = (0, require_role_1.requireVendor)(request);
    const input = request.data ?? {};
    const category = (0, sanitize_1.cleanDocId)(input.category, "category");
    if (!(await firebase_1.db.collection("categories").doc(category).get()).exists) {
        throw new https_1.HttpsError("invalid-argument", "Choose a category from the list.");
    }
    const brand = (0, sanitize_1.cleanText)(input.brand, "brand", { max: 80, min: 1 });
    const name = (0, sanitize_1.cleanLocalized)(input.name, "Product name", { max: 120 });
    const spec = (0, sanitize_1.cleanText)(input.spec, "spec", { max: 120 });
    const description = (0, sanitize_1.cleanLocalized)(input.description, "Description", { max: 2000, multiline: true, optional: true });
    const warranty = (0, sanitize_1.cleanLocalized)(input.warranty, "Warranty", { max: 120, optional: true });
    const price = (0, sanitize_1.cleanPrice)(input.price);
    const currency = (0, sanitize_1.cleanEnum)(input.currency ?? "USD", ["USD", "IQD"], "currency");
    let wattage = null;
    if (input.wattage !== undefined && input.wattage !== null) {
        if (!Number.isInteger(input.wattage) || input.wattage <= 0 || input.wattage > 1000000) {
            throw new https_1.HttpsError("invalid-argument", "wattage must be a positive whole number.");
        }
        wattage = input.wattage;
    }
    if (!(0, store_image_1.isOwnedImageUrl)(input.imageUrl, `productImages/${vendorId}`)) {
        throw new https_1.HttpsError("invalid-argument", "Upload a product image first.");
    }
    const productRef = firebase_1.db.collection("products").doc();
    await productRef.set({
        vendorId,
        category,
        brand,
        // `name`/`description`/`warranty` stay plain English strings so existing
        // readers (mobile storefront) keep working; the full ku/ar/en set lives
        // in the *I18n fields.
        name: name.en,
        nameI18n: name,
        spec,
        wattage,
        price,
        currency,
        inStock: true,
        rating: 0,
        sold: 0,
        warranty: warranty?.en ?? null,
        warrantyI18n: warranty,
        description: description?.en ?? null,
        descriptionI18n: description,
        imageUrl: input.imageUrl,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return { productId: productRef.id };
});
