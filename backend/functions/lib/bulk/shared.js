"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.COUNTRIES = void 0;
exports.requireBulkVendor = requireBulkVendor;
exports.cleanQuantity = cleanQuantity;
exports.cleanCategoryId = cleanCategoryId;
const https_1 = require("firebase-functions/v2/https");
const firebase_1 = require("../shared/firebase");
const require_role_1 = require("../shared/auth/require_role");
const sanitize_1 = require("../shared/validation/sanitize");
exports.COUNTRIES = ["IQ", "CN"];
/// Bulk marketplace is for approved vendors only: bulk prices and buyer
/// requests are never exposed to shoppers. Returns the caller's vendor
/// profile fields that get denormalized onto each post (so listing a
/// feed never needs a per-row vendor lookup). Vendors approved before
/// `country` existed default to Iraq.
async function requireBulkVendor(request) {
    const { uid, vendorId } = (0, require_role_1.requireVendor)(request);
    const snap = await firebase_1.db.collection("vendors").doc(vendorId).get();
    const vendor = snap.data();
    if (!snap.exists || !vendor || vendor.status !== "approved") {
        throw new https_1.HttpsError("permission-denied", "Vendor account is not approved.");
    }
    return {
        uid,
        vendorId,
        businessName: vendor.businessName ?? "",
        country: vendor.country === "CN" ? "CN" : "IQ",
        city: vendor.city ?? "",
        phone: vendor.phone ?? "",
        logoUrl: vendor.logoUrl ?? "",
    };
}
/// Positive whole number within [1, max] — quantities are units of
/// product, never fractional.
function cleanQuantity(value, field, max = 10000000) {
    if (typeof value !== "number" || !Number.isInteger(value) || value < 1 || value > max) {
        throw new https_1.HttpsError("invalid-argument", `${field} must be a whole number between 1 and ${max}.`);
    }
    return value;
}
/// Optional category for a post. Must be an existing admin-managed
/// `categories` doc (same list the storefront filters by) — never a
/// free-form value — or null for "no category".
async function cleanCategoryId(value) {
    if (value === undefined || value === null || value === "")
        return null;
    const id = (0, sanitize_1.cleanDocId)(value, "categoryId");
    const snap = await firebase_1.db.collection("categories").doc(id).get();
    if (!snap.exists) {
        throw new https_1.HttpsError("invalid-argument", "Unknown category.");
    }
    return id;
}
