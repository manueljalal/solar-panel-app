"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteCategory = exports.updateCategory = exports.createCategory = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const require_role_1 = require("../shared/auth/require_role");
const store_image_1 = require("../shared/images/store_image");
const sanitize_1 = require("../shared/validation/sanitize");
/// categories/{slug} -> { name: { ku, ar, en } }. The doc id is the slug,
/// derived once from the English name and never changed, so products can
/// reference it (products.category) without it shifting under them when a
/// name is later edited. Reads are public (Firestore rules) — the vendor
/// portal and storefront list categories directly; writes are admin-only
/// and go through these callables.
const MAX_CATEGORIES = 200;
function slugify(en) {
    return en
        .toLowerCase()
        .normalize("NFKD")
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/^-+|-+$/g, "")
        .slice(0, 60);
}
exports.createCategory = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    const { uid } = (0, require_role_1.requireRole)(request, ["super_admin"]);
    const name = (0, sanitize_1.cleanLocalized)(request.data?.name, "Category name");
    const imageUrl = request.data?.imageUrl;
    if (!(0, store_image_1.isOwnedImageUrl)(imageUrl, "categoryImages")) {
        throw new https_1.HttpsError("invalid-argument", "Upload a category image.");
    }
    const slug = slugify(name.en);
    if (!slug) {
        throw new https_1.HttpsError("invalid-argument", "English name must contain letters or numbers.");
    }
    const ref = firebase_1.db.collection("categories").doc(slug);
    await firebase_1.db.runTransaction(async (tx) => {
        if ((await tx.get(ref)).exists) {
            throw new https_1.HttpsError("already-exists", "A category with this English name already exists.");
        }
        tx.set(ref, { name, imageUrl, createdAt: firestore_1.FieldValue.serverTimestamp(), updatedAt: firestore_1.FieldValue.serverTimestamp(), createdBy: uid });
    });
    // Cheap guard against runaway creation; checked after so a race can only
    // overshoot by a handful, which is harmless.
    const count = await firebase_1.db.collection("categories").count().get();
    if (count.data().count > MAX_CATEGORIES) {
        await ref.delete();
        throw new https_1.HttpsError("resource-exhausted", `At most ${MAX_CATEGORIES} categories.`);
    }
    return { categoryId: slug };
});
exports.updateCategory = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    (0, require_role_1.requireRole)(request, ["super_admin"]);
    const categoryId = (0, sanitize_1.cleanDocId)(request.data?.categoryId, "categoryId");
    const name = (0, sanitize_1.cleanLocalized)(request.data?.name, "Category name");
    // Optional on update: omitted = keep the current image.
    const imageUrl = request.data?.imageUrl;
    if (imageUrl !== undefined && !(0, store_image_1.isOwnedImageUrl)(imageUrl, "categoryImages")) {
        throw new https_1.HttpsError("invalid-argument", "Upload a category image.");
    }
    const ref = firebase_1.db.collection("categories").doc(categoryId);
    if (!(await ref.get()).exists) {
        throw new https_1.HttpsError("not-found", "Category not found.");
    }
    await ref.update({ name, ...(imageUrl ? { imageUrl } : {}), updatedAt: firestore_1.FieldValue.serverTimestamp() });
    return { ok: true };
});
exports.deleteCategory = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    (0, require_role_1.requireRole)(request, ["super_admin"]);
    const categoryId = (0, sanitize_1.cleanDocId)(request.data?.categoryId, "categoryId");
    const inUse = await firebase_1.db.collection("products").where("category", "==", categoryId).limit(1).get();
    if (!inUse.empty) {
        throw new https_1.HttpsError("failed-precondition", "Products still use this category — it can't be deleted.");
    }
    await firebase_1.db.collection("categories").doc(categoryId).delete();
    return { ok: true };
});
