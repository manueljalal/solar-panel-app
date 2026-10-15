import { randomUUID } from "crypto";
import { getStorage } from "firebase-admin/storage";
import { HttpsError } from "firebase-functions/v2/https";
import "../firebase"; // ensures the Admin app is initialized

export const MAX_VIDEO_BYTES = 50 * 1024 * 1024;

// The admin browser picks the object name, but Storage rules only allow
// this exact shape, and we re-check it here.
const VIDEO_PATH = /^learnVideos\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.mp4$/;

export function assertVideoPath(path: unknown): asserts path is string {
  if (typeof path !== "string" || !VIDEO_PATH.test(path)) {
    throw new HttpsError("invalid-argument", "Upload a video first.");
  }
}

/// Verifies an object the admin uploaded straight to Storage really is a
/// reasonable MP4 — never trust the upload rule alone: re-read size and
/// content type from storage metadata and sniff the file header (an MP4
/// has an `ftyp` box at byte 4). Then attaches an unguessable download
/// token and returns the playable URL. A file that fails any check is
/// deleted so it can't linger unreferenced.
export async function verifyAndPublishVideo(path: string): Promise<string> {
  const bucket = getStorage().bucket();
  const file = bucket.file(path);

  const [exists] = await file.exists();
  if (!exists) {
    throw new HttpsError("invalid-argument", "The video upload didn't finish — try again.");
  }

  const [meta] = await file.getMetadata();
  const size = Number(meta.size ?? 0);
  const reject = async (message: string): Promise<never> => {
    await file.delete({ ignoreNotFound: true });
    throw new HttpsError("invalid-argument", message);
  };

  if (!size || size > MAX_VIDEO_BYTES) {
    return reject("Video must be 50 MB or smaller.");
  }
  if (meta.contentType !== "video/mp4") {
    return reject("Only MP4 videos are allowed.");
  }

  const [head] = await file.download({ start: 0, end: 11 });
  if (head.length < 12 || head.toString("ascii", 4, 8) !== "ftyp") {
    return reject("That file isn't a valid MP4 video.");
  }

  const token = randomUUID();
  await file.setMetadata({
    cacheControl: "public, max-age=31536000, immutable",
    contentDisposition: "inline",
    metadata: { firebaseStorageDownloadTokens: token },
  });
  return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;
}

export async function deleteVideo(path: unknown): Promise<void> {
  if (typeof path !== "string" || !VIDEO_PATH.test(path)) return;
  await getStorage().bucket().file(path).delete({ ignoreNotFound: true });
}
