"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateProfile = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const require_role_1 = require("../shared/auth/require_role");
const store_image_1 = require("../shared/images/store_image");
const sanitize_1 = require("../shared/validation/sanitize");
/// Vendor edits its public company profile (shown on the company page and
/// next to its products and B2B posts). The phone stays fixed: it is the
/// account's verified login number.
exports.updateProfile = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    const { uid, vendorId } = (0, require_role_1.requireVendor)(request);
    const businessName = (0, sanitize_1.cleanText)(request.data?.businessName, "businessName", { max: 120, min: 1 });
    const city = (0, sanitize_1.cleanText)(request.data?.city, "city", { max: 80, min: 1 });
    const address = (0, sanitize_1.cleanText)(request.data?.address, "address", { max: 300 });
    const description = (0, sanitize_1.cleanText)(request.data?.description, "description", { max: 1000, multiline: true });
    const update = {
        businessName, city, address, description, updatedAt: firestore_1.FieldValue.serverTimestamp(),
    };
    const logoUrl = request.data?.logoUrl;
    if (logoUrl) {
        if (!(0, store_image_1.isOwnedImageUrl)(logoUrl, `companyLogos/${uid}`)) {
            throw new https_1.HttpsError("invalid-argument", "Upload the logo through the portal first.");
        }
        update.logoUrl = logoUrl;
    }
    await firebase_1.db.collection("vendors").doc(vendorId).update(update);
    return { ok: true };
});
