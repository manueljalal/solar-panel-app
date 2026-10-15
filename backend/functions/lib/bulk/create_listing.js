"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createListing = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const sanitize_1 = require("../shared/validation/sanitize");
const store_image_1 = require("../shared/images/store_image");
const shared_1 = require("./shared");
const MAX_TIERS = 5;
/// Vendor-only. Posts a wholesale listing: a product offered in bulk with
/// quantity-tier pricing (e.g. 100+ units = $X, 500+ = $Y). Visible only
/// to other approved vendors via bulk-listListings.
exports.createListing = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    const me = await (0, shared_1.requireBulkVendor)(request);
    const titleI18n = (0, sanitize_1.cleanMultilingual)(request.data?.title, "title", { max: 120 });
    const descriptionI18n = (0, sanitize_1.cleanMultilingual)(request.data?.description, "description", {
        max: 1000,
        multiline: true,
        optional: true,
    });
    const imageUrl = request.data?.imageUrl;
    if (imageUrl && !(0, store_image_1.isOwnedImageUrl)(imageUrl, `productImages/${me.vendorId}`)) {
        throw new https_1.HttpsError("invalid-argument", "Upload the photo through the app first.");
    }
    const unit = (0, sanitize_1.cleanText)(request.data?.unit || "pcs", "unit", { max: 20, min: 1 });
    const categoryId = await (0, shared_1.cleanCategoryId)(request.data?.categoryId);
    const rawTiers = request.data?.tiers;
    if (!Array.isArray(rawTiers) || rawTiers.length < 1 || rawTiers.length > MAX_TIERS) {
        throw new https_1.HttpsError("invalid-argument", `Add between 1 and ${MAX_TIERS} price tiers.`);
    }
    const tiers = rawTiers
        .map((t, i) => {
        if (typeof t !== "object" || t === null)
            throw new https_1.HttpsError("invalid-argument", `tier ${i + 1} is invalid.`);
        return {
            minQty: (0, shared_1.cleanQuantity)(t.minQty, `tier ${i + 1} quantity`),
            unitPriceUsd: (0, sanitize_1.cleanPrice)(t.unitPriceUsd, `tier ${i + 1} price`),
        };
    })
        .sort((a, b) => a.minQty - b.minQty);
    for (let i = 1; i < tiers.length; i++) {
        if (tiers[i].minQty === tiers[i - 1].minQty) {
            throw new https_1.HttpsError("invalid-argument", "Each price tier needs a different quantity.");
        }
    }
    const ref = firebase_1.db.collection("bulkListings").doc();
    await ref.set({
        vendorId: me.vendorId,
        ownerUid: me.uid,
        businessName: me.businessName,
        country: me.country,
        city: me.city,
        phone: me.phone,
        logoUrl: me.logoUrl,
        categoryId,
        title: (0, sanitize_1.primaryText)(titleI18n),
        titleI18n,
        description: (0, sanitize_1.primaryText)(descriptionI18n),
        descriptionI18n,
        imageUrl: imageUrl || null,
        unit,
        tiers,
        moq: tiers[0].minQty,
        status: "active",
        createdAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return { id: ref.id };
});
