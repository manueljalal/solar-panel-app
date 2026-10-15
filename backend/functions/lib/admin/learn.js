"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteLearnItem = exports.updateLearnItem = exports.createLearnItem = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const require_role_1 = require("../shared/auth/require_role");
const store_image_1 = require("../shared/images/store_image");
const verify_video_1 = require("../shared/videos/verify_video");
const sanitize_1 = require("../shared/validation/sanitize");
/// learnItems/{id} -> { title, description: {ku,ar,en}, videoPath, videoUrl,
/// createdAt }. Read publicly by the mobile Learn tab (Firestore rules);
/// written only through these super_admin callables. The video itself is
/// uploaded by the admin browser directly to Storage (too large for a
/// callable payload) and then verified + published here.
const MAX_ITEMS = 50;
function cleanThumbnail(value) {
    if (value === undefined || value === null)
        return null;
    if (!(0, store_image_1.isOwnedImageUrl)(value, "learnThumbnails")) {
        throw new https_1.HttpsError("invalid-argument", "Thumbnail is invalid.");
    }
    return value;
}
function cleanDuration(value) {
    if (value === undefined || value === null)
        return null;
    if (typeof value !== "number" || !Number.isFinite(value) || value <= 0 || value > 4 * 3600) {
        throw new https_1.HttpsError("invalid-argument", "Video length is invalid.");
    }
    return Math.round(value);
}
exports.createLearnItem = (0, https_1.onCall)({ region: "us-central1", memory: "512MiB" }, async (request) => {
    const { uid } = (0, require_role_1.requireRole)(request, ["super_admin"]);
    const title = (0, sanitize_1.cleanLocalized)(request.data?.title, "Title", { max: 120 });
    const description = (0, sanitize_1.cleanLocalized)(request.data?.description, "Description", { max: 2000, multiline: true });
    const videoPath = request.data?.videoPath;
    (0, verify_video_1.assertVideoPath)(videoPath);
    const thumbnailUrl = cleanThumbnail(request.data?.thumbnailUrl);
    const durationSec = cleanDuration(request.data?.durationSec);
    // Each uploaded file may back exactly one item.
    const taken = await firebase_1.db.collection("learnItems").where("videoPath", "==", videoPath).limit(1).get();
    if (!taken.empty) {
        throw new https_1.HttpsError("already-exists", "That video is already used.");
    }
    const count = await firebase_1.db.collection("learnItems").count().get();
    if (count.data().count >= MAX_ITEMS) {
        await (0, verify_video_1.deleteVideo)(videoPath);
        throw new https_1.HttpsError("failed-precondition", `At most ${MAX_ITEMS} learn items. Delete one first.`);
    }
    const videoUrl = await (0, verify_video_1.verifyAndPublishVideo)(videoPath);
    const ref = firebase_1.db.collection("learnItems").doc();
    await ref.set({
        title,
        description,
        videoPath,
        videoUrl,
        thumbnailUrl,
        durationSec,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        createdBy: uid,
    });
    return { learnItemId: ref.id };
});
exports.updateLearnItem = (0, https_1.onCall)({ region: "us-central1", memory: "512MiB" }, async (request) => {
    (0, require_role_1.requireRole)(request, ["super_admin"]);
    const id = (0, sanitize_1.cleanDocId)(request.data?.learnItemId, "learnItemId");
    const ref = firebase_1.db.collection("learnItems").doc(id);
    const snap = await ref.get();
    if (!snap.exists)
        throw new https_1.HttpsError("not-found", "Learn item not found.");
    const patch = { updatedAt: firestore_1.FieldValue.serverTimestamp() };
    if (request.data.title !== undefined) {
        patch.title = (0, sanitize_1.cleanLocalized)(request.data.title, "Title", { max: 120 });
    }
    if (request.data.description !== undefined) {
        patch.description = (0, sanitize_1.cleanLocalized)(request.data.description, "Description", { max: 2000, multiline: true });
    }
    // Cover image can be changed on its own (no new video needed).
    if ("thumbnailUrl" in request.data) {
        patch.thumbnailUrl = cleanThumbnail(request.data.thumbnailUrl);
    }
    let oldPath = null;
    if (request.data.videoPath !== undefined && request.data.videoPath !== snap.data().videoPath) {
        (0, verify_video_1.assertVideoPath)(request.data.videoPath);
        const taken = await firebase_1.db.collection("learnItems").where("videoPath", "==", request.data.videoPath).limit(1).get();
        if (!taken.empty)
            throw new https_1.HttpsError("already-exists", "That video is already used.");
        patch.videoUrl = await (0, verify_video_1.verifyAndPublishVideo)(request.data.videoPath);
        patch.videoPath = request.data.videoPath;
        patch.durationSec = cleanDuration(request.data.durationSec);
        // A replaced video must not keep the old video's cover.
        patch.thumbnailUrl = null;
        oldPath = snap.data().videoPath;
    }
    if (oldPath && "thumbnailUrl" in request.data) {
        patch.thumbnailUrl = cleanThumbnail(request.data.thumbnailUrl);
    }
    await ref.update(patch);
    if (oldPath)
        await (0, verify_video_1.deleteVideo)(oldPath);
    return { ok: true };
});
exports.deleteLearnItem = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    (0, require_role_1.requireRole)(request, ["super_admin"]);
    const ref = firebase_1.db.collection("learnItems").doc((0, sanitize_1.cleanDocId)(request.data?.learnItemId, "learnItemId"));
    const snap = await ref.get();
    if (!snap.exists)
        return { ok: true };
    await ref.delete();
    await (0, verify_video_1.deleteVideo)(snap.data().videoPath);
    return { ok: true };
});
