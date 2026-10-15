"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.uploadImage = void 0;
const https_1 = require("firebase-functions/v2/https");
const store_image_1 = require("../shared/images/store_image");
const sanitize_1 = require("../shared/validation/sanitize");
/// Signed-in (non-anonymous) users may upload a company logo for their
/// vendor application; approved vendors may upload product images. The
/// storage folder is derived from the verified token, never from client
/// input, so one account can't write into another's folder.
exports.uploadImage = (0, https_1.onCall)({ region: "us-central1", memory: "512MiB" }, async (request) => {
    const auth = request.auth;
    if (!auth)
        throw new https_1.HttpsError("unauthenticated", "Sign in required.");
    if (auth.token.firebase?.sign_in_provider === "anonymous") {
        throw new https_1.HttpsError("permission-denied", "Create an account to upload images.");
    }
    const purpose = (0, sanitize_1.cleanEnum)(request.data?.purpose, ["company-logo", "product", "category", "banner", "learn"], "purpose");
    let folder;
    if (purpose === "company-logo") {
        folder = `companyLogos/${auth.uid}`;
    }
    else if (purpose === "category" || purpose === "banner" || purpose === "learn") {
        // Admin-managed images; one shared folder per purpose.
        if (auth.token.role !== "super_admin") {
            throw new https_1.HttpsError("permission-denied", "Only admins can upload this image.");
        }
        folder = purpose === "category" ? "categoryImages" : purpose === "banner" ? "bannerImages" : "learnThumbnails";
    }
    else {
        const vendorId = auth.token.vendorId;
        if (auth.token.role !== "vendor" || !vendorId) {
            throw new https_1.HttpsError("permission-denied", "Only approved vendors can upload product images.");
        }
        folder = `productImages/${vendorId}`;
    }
    return { url: await (0, store_image_1.storeImage)(request.data?.data, folder) };
});
