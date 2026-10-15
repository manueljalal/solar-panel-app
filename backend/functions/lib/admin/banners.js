"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteBanner = exports.updateBanner = exports.createBanner = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const require_role_1 = require("../shared/auth/require_role");
const store_image_1 = require("../shared/images/store_image");
const sanitize_1 = require("../shared/validation/sanitize");
/// banners/{id} -> { imageUrl, title?: { ku, ar, en }, createdAt }. The
/// mobile home carousel reads this collection directly (public read in
/// Firestore rules); only a super_admin can change it, through these
/// callables. At most MAX_BANNERS exist at any time — enforced here, inside
/// a transaction, not just in the admin UI.
const MAX_BANNERS = 5;
/// Optional overlay shade behind the headline, as #RRGGBB. null = none.
function cleanOverlay(value) {
    if (value === undefined || value === null || value === "")
        return null;
    if (typeof value !== "string" || !/^#[0-9a-fA-F]{6}$/.test(value)) {
        throw new https_1.HttpsError("invalid-argument", "Overlay color must look like #1F5A44.");
    }
    return value.toUpperCase();
}
exports.createBanner = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    const { uid } = (0, require_role_1.requireRole)(request, ["super_admin"]);
    const imageUrl = request.data?.imageUrl;
    if (!(0, store_image_1.isOwnedImageUrl)(imageUrl, "bannerImages")) {
        throw new https_1.HttpsError("invalid-argument", "Upload a banner image.");
    }
    const title = (0, sanitize_1.cleanLocalized)(request.data?.title, "Banner title", { max: 80, optional: true });
    const overlayColor = cleanOverlay(request.data?.overlayColor);
    const ref = firebase_1.db.collection("banners").doc();
    await firebase_1.db.runTransaction(async (tx) => {
        // The transaction re-runs if another banner is created concurrently, so
        // two simultaneous requests can't both slip past the limit.
        const existing = await tx.get(firebase_1.db.collection("banners").limit(MAX_BANNERS));
        if (existing.size >= MAX_BANNERS) {
            throw new https_1.HttpsError("failed-precondition", `You can have at most ${MAX_BANNERS} banners. Delete one first.`);
        }
        tx.set(ref, {
            imageUrl,
            title,
            overlayColor,
            createdAt: firestore_1.FieldValue.serverTimestamp(),
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
            createdBy: uid,
        });
    });
    return { bannerId: ref.id };
});
exports.updateBanner = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    (0, require_role_1.requireRole)(request, ["super_admin"]);
    const bannerId = (0, sanitize_1.cleanDocId)(request.data?.bannerId, "bannerId");
    const patch = { updatedAt: firestore_1.FieldValue.serverTimestamp() };
    if (request.data?.imageUrl !== undefined) {
        if (!(0, store_image_1.isOwnedImageUrl)(request.data.imageUrl, "bannerImages")) {
            throw new https_1.HttpsError("invalid-argument", "Upload a banner image.");
        }
        patch.imageUrl = request.data.imageUrl;
    }
    // `title` present (even null) means "set it"; absent means "leave it".
    if (request.data && "title" in request.data) {
        patch.title = (0, sanitize_1.cleanLocalized)(request.data.title, "Banner title", { max: 80, optional: true });
    }
    if (request.data && "overlayColor" in request.data) {
        patch.overlayColor = cleanOverlay(request.data.overlayColor);
    }
    const ref = firebase_1.db.collection("banners").doc(bannerId);
    if (!(await ref.get()).exists) {
        throw new https_1.HttpsError("not-found", "Banner not found.");
    }
    await ref.update(patch);
    return { ok: true };
});
exports.deleteBanner = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    (0, require_role_1.requireRole)(request, ["super_admin"]);
    await firebase_1.db.collection("banners").doc((0, sanitize_1.cleanDocId)(request.data?.bannerId, "bannerId")).delete();
    return { ok: true };
});
