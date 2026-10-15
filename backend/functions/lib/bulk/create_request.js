"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createRequest = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const sanitize_1 = require("../shared/validation/sanitize");
const store_image_1 = require("../shared/images/store_image");
const shared_1 = require("./shared");
/// Vendor-only. A buyer request ("I need 500 x 450W panels") that other
/// approved vendors — Iraqi or Chinese — can answer by contacting the
/// poster. targetPriceUsd is optional: many buyers want quotes, not to
/// anchor a price.
exports.createRequest = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
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
    const quantity = (0, shared_1.cleanQuantity)(request.data?.quantity, "quantity");
    const deliveryCity = (0, sanitize_1.cleanText)(request.data?.deliveryCity, "deliveryCity", { max: 80 });
    const rawTarget = request.data?.targetPriceUsd;
    let targetPriceUsd = null;
    if (rawTarget !== undefined && rawTarget !== null) {
        targetPriceUsd = (0, sanitize_1.cleanPrice)(rawTarget, "targetPriceUsd");
    }
    const ref = firebase_1.db.collection("bulkRequests").doc();
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
        quantity,
        targetPriceUsd,
        deliveryCity,
        status: "open",
        createdAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return { id: ref.id };
});
