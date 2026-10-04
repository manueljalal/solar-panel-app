"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createProduct = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const require_role_1 = require("../shared/auth/require_role");
const MAX_STRING_LENGTH = 500; // basic abuse/perf guard, not just validation
function assertReasonableStrings(input) {
    for (const [key, value] of Object.entries(input)) {
        if (typeof value === "string" && value.length > MAX_STRING_LENGTH) {
            throw new https_1.HttpsError("invalid-argument", `${key} exceeds ${MAX_STRING_LENGTH} characters.`);
        }
    }
}
/// Vendor-only. This is the actual "upload a product" operation — the
/// piece that was completely missing before: every product in Firestore
/// until now came from a one-off seed script, not from a real vendor.
exports.createProduct = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    const { vendorId } = (0, require_role_1.requireVendor)(request);
    const input = request.data;
    if (!input.name || !input.brand || !input.category || typeof input.price !== "number") {
        throw new https_1.HttpsError("invalid-argument", "name, brand, category, and price are required.");
    }
    if (input.price <= 0 || input.price > 1000000) {
        throw new https_1.HttpsError("invalid-argument", "price must be a sane positive number.");
    }
    assertReasonableStrings(input);
    const productRef = firebase_1.db.collection("products").doc();
    await productRef.set({
        vendorId,
        category: input.category,
        brand: input.brand,
        name: input.name,
        spec: input.spec ?? "",
        wattage: input.wattage ?? null,
        price: input.price,
        currency: input.currency ?? "USD",
        inStock: true,
        rating: 0,
        sold: 0,
        warranty: input.warranty ?? null,
        description: input.description ?? null,
        imageUrl: input.imageUrl ?? "",
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return { productId: productRef.id };
});
