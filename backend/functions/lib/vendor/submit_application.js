"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.submitApplication = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const store_image_1 = require("../shared/images/store_image");
const rate_limit_1 = require("../shared/rate_limit");
const sanitize_1 = require("../shared/validation/sanitize");
const E164_PATTERN = /^\+[1-9]\d{6,14}$/;
/// Any signed-in user may apply to become a vendor (see Account tab's
/// "Own a solar business? Apply" and the web vendor portal's /apply
/// page). Writes the vendorApplications doc server-side instead of the
/// client writing it directly — uid comes from the verified auth token,
/// never a client-supplied field.
exports.submitApplication = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Sign in required.");
    }
    const uid = request.auth.uid;
    const userSnap = await firebase_1.db.collection("users").doc(uid).get();
    const phone = userSnap.data()?.phone?.trim();
    if (!phone) {
        throw new https_1.HttpsError("failed-precondition", "A verified phone number is required to apply.");
    }
    if (!E164_PATTERN.test(phone)) {
        throw new https_1.HttpsError("internal", "Verified phone number is malformed.");
    }
    const businessName = (0, sanitize_1.cleanText)(request.data?.businessName, "businessName", { max: 120, min: 1 });
    const city = (0, sanitize_1.cleanText)(request.data?.city, "city", { max: 80, min: 1 });
    const address = (0, sanitize_1.cleanText)(request.data?.address, "address", { max: 300 });
    const email = (0, sanitize_1.cleanEmail)(request.data?.email);
    const country = (0, sanitize_1.cleanEnum)(request.data?.country ?? "IQ", ["IQ", "CN"], "country");
    const note = (0, sanitize_1.cleanText)(request.data?.note, "note", { max: 1000, multiline: true });
    // Only a URL our own upload endpoint issued for THIS account's folder is
    // accepted — never an arbitrary external URL.
    const logoUrl = request.data?.logoUrl;
    if (!(0, store_image_1.isOwnedImageUrl)(logoUrl, `companyLogos/${uid}`)) {
        throw new https_1.HttpsError("invalid-argument", "Upload an image of your company.");
    }
    const location = (0, sanitize_1.cleanLocation)(request.data?.location);
    await (0, rate_limit_1.consumeRateLimit)("vendorApplication", uid, {
        max: 3,
        windowMs: 24 * 60 * 60 * 1000,
        message: "You've already applied today. We'll review your application soon.",
    });
    const applicationRef = firebase_1.db.collection("vendorApplications").doc();
    await applicationRef.set({
        uid,
        businessName,
        city,
        address,
        phone,
        email,
        country,
        note,
        logoUrl,
        location,
        status: "pending",
        createdAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return { applicationId: applicationRef.id };
});
