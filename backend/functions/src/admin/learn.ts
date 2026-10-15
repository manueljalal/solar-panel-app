import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { requireRole } from "../shared/auth/require_role";
import { isOwnedImageUrl } from "../shared/images/store_image";
import { assertVideoPath, deleteVideo, verifyAndPublishVideo } from "../shared/videos/verify_video";
import { cleanDocId, cleanLocalized, type LocalizedText } from "../shared/validation/sanitize";

/// learnItems/{id} -> { title, description: {ku,ar,en}, videoPath, videoUrl,
/// createdAt }. Read publicly by the mobile Learn tab (Firestore rules);
/// written only through these super_admin callables. The video itself is
/// uploaded by the admin browser directly to Storage (too large for a
/// callable payload) and then verified + published here.
const MAX_ITEMS = 50;

interface LearnInput {
  title: LocalizedText;
  description: LocalizedText;
  /** Storage path of the uploaded MP4 (learnVideos/<uuid>.mp4). */
  videoPath: string;
  /** Frame captured from the video in the admin browser (purpose "learn"). */
  thumbnailUrl?: string | null;
  /** Video length in seconds, read by the admin browser. */
  durationSec?: number | null;
}

function cleanThumbnail(value: unknown): string | null {
  if (value === undefined || value === null) return null;
  if (!isOwnedImageUrl(value, "learnThumbnails")) {
    throw new HttpsError("invalid-argument", "Thumbnail is invalid.");
  }
  return value;
}

function cleanDuration(value: unknown): number | null {
  if (value === undefined || value === null) return null;
  if (typeof value !== "number" || !Number.isFinite(value) || value <= 0 || value > 4 * 3600) {
    throw new HttpsError("invalid-argument", "Video length is invalid.");
  }
  return Math.round(value);
}

export const createLearnItem = onCall<LearnInput>({ region: "us-central1", memory: "512MiB" }, async (request) => {
  const { uid } = requireRole(request, ["super_admin"]);
  const title = cleanLocalized(request.data?.title, "Title", { max: 120 });
  const description = cleanLocalized(request.data?.description, "Description", { max: 2000, multiline: true });
  const videoPath = request.data?.videoPath;
  assertVideoPath(videoPath);
  const thumbnailUrl = cleanThumbnail(request.data?.thumbnailUrl);
  const durationSec = cleanDuration(request.data?.durationSec);

  // Each uploaded file may back exactly one item.
  const taken = await db.collection("learnItems").where("videoPath", "==", videoPath).limit(1).get();
  if (!taken.empty) {
    throw new HttpsError("already-exists", "That video is already used.");
  }
  const count = await db.collection("learnItems").count().get();
  if (count.data().count >= MAX_ITEMS) {
    await deleteVideo(videoPath);
    throw new HttpsError("failed-precondition", `At most ${MAX_ITEMS} learn items. Delete one first.`);
  }

  const videoUrl = await verifyAndPublishVideo(videoPath);
  const ref = db.collection("learnItems").doc();
  await ref.set({
    title,
    description,
    videoPath,
    videoUrl,
    thumbnailUrl,
    durationSec,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    createdBy: uid,
  });
  return { learnItemId: ref.id };
});

export const updateLearnItem = onCall<Partial<LearnInput> & { learnItemId: string }>(
  { region: "us-central1", memory: "512MiB" },
  async (request) => {
    requireRole(request, ["super_admin"]);
    const id = cleanDocId(request.data?.learnItemId, "learnItemId");
    const ref = db.collection("learnItems").doc(id);
    const snap = await ref.get();
    if (!snap.exists) throw new HttpsError("not-found", "Learn item not found.");

    const patch: Record<string, unknown> = { updatedAt: FieldValue.serverTimestamp() };
    if (request.data.title !== undefined) {
      patch.title = cleanLocalized(request.data.title, "Title", { max: 120 });
    }
    if (request.data.description !== undefined) {
      patch.description = cleanLocalized(request.data.description, "Description", { max: 2000, multiline: true });
    }

    // Cover image can be changed on its own (no new video needed).
    if ("thumbnailUrl" in request.data) {
      patch.thumbnailUrl = cleanThumbnail(request.data.thumbnailUrl);
    }

    let oldPath: string | null = null;
    if (request.data.videoPath !== undefined && request.data.videoPath !== snap.data()!.videoPath) {
      assertVideoPath(request.data.videoPath);
      const taken = await db.collection("learnItems").where("videoPath", "==", request.data.videoPath).limit(1).get();
      if (!taken.empty) throw new HttpsError("already-exists", "That video is already used.");
      patch.videoUrl = await verifyAndPublishVideo(request.data.videoPath);
      patch.videoPath = request.data.videoPath;
      patch.durationSec = cleanDuration(request.data.durationSec);
      // A replaced video must not keep the old video's cover.
      patch.thumbnailUrl = null;
      oldPath = snap.data()!.videoPath as string;
    }

    if (oldPath && "thumbnailUrl" in request.data) {
      patch.thumbnailUrl = cleanThumbnail(request.data.thumbnailUrl);
    }
    await ref.update(patch);
    if (oldPath) await deleteVideo(oldPath);
    return { ok: true };
  },
);

export const deleteLearnItem = onCall<{ learnItemId: string }>({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);
  const ref = db.collection("learnItems").doc(cleanDocId(request.data?.learnItemId, "learnItemId"));
  const snap = await ref.get();
  if (!snap.exists) return { ok: true };
  await ref.delete();
  await deleteVideo(snap.data()!.videoPath);
  return { ok: true };
});
