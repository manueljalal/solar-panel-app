import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { requireRole } from "../shared/auth/require_role";
import { isOwnedImageUrl } from "../shared/images/store_image";
import { cleanDocId, cleanEnum, cleanLocalized, cleanText, type LocalizedText } from "../shared/validation/sanitize";

/// courses/{id} -> { title, description: {ku,ar,en}, coverUrl, access,
/// priceLabel, order }. Episodes are learnItems with this courseId. Read
/// publicly by the app's Learn tab; written only here.
///
/// access "paid" is shown in the app as Premium: the first episode plays as
/// a free preview and the rest are locked ("coming soon"). There is no
/// payment yet, and episode video URLs are still public — a real paywall
/// must move playback behind a function before charging money.
interface CourseInput {
  title: LocalizedText;
  description: LocalizedText;
  coverUrl?: string | null;
  access?: "free" | "paid";
  /** Display only, e.g. "$10" or "15,000 IQD". */
  priceLabel?: string;
  /** Lower comes first. */
  order?: number;
}

function cleanCover(value: unknown): string | null {
  if (value === undefined || value === null || value === "") return null;
  if (!isOwnedImageUrl(value, "learnThumbnails")) throw new HttpsError("invalid-argument", "Upload the cover image first.");
  return value as string;
}

function cleanOrder(value: unknown): number {
  if (value === undefined || value === null) return 100;
  if (typeof value !== "number" || !Number.isInteger(value) || value < 0 || value > 10_000) {
    throw new HttpsError("invalid-argument", "Order must be a whole number.");
  }
  return value;
}

export const createCourse = onCall<CourseInput>({ region: "us-central1" }, async (request) => {
  const { uid } = requireRole(request, ["super_admin"]);
  const ref = db.collection("courses").doc();
  await ref.set({
    title: cleanLocalized(request.data?.title, "Course title", { max: 120 }),
    description: cleanLocalized(request.data?.description, "Course description", { max: 2000, multiline: true }),
    coverUrl: cleanCover(request.data?.coverUrl),
    access: cleanEnum(request.data?.access ?? "free", ["free", "paid"] as const, "access"),
    priceLabel: cleanText(request.data?.priceLabel, "priceLabel", { max: 40 }),
    order: cleanOrder(request.data?.order),
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    createdBy: uid,
  });
  return { courseId: ref.id };
});

export const updateCourse = onCall<Partial<CourseInput> & { courseId: string }>({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);
  const ref = db.collection("courses").doc(cleanDocId(request.data?.courseId, "courseId"));
  if (!(await ref.get()).exists) throw new HttpsError("not-found", "Course not found.");
  const d = request.data;
  const patch: Record<string, unknown> = { updatedAt: FieldValue.serverTimestamp() };
  if (d.title !== undefined) patch.title = cleanLocalized(d.title, "Course title", { max: 120 });
  if (d.description !== undefined) {
    patch.description = cleanLocalized(d.description, "Course description", { max: 2000, multiline: true });
  }
  if ("coverUrl" in d) patch.coverUrl = cleanCover(d.coverUrl);
  if (d.access !== undefined) patch.access = cleanEnum(d.access, ["free", "paid"] as const, "access");
  if (d.priceLabel !== undefined) patch.priceLabel = cleanText(d.priceLabel, "priceLabel", { max: 40 });
  if (d.order !== undefined) patch.order = cleanOrder(d.order);
  await ref.update(patch);
  return { ok: true };
});

/// Deletes a course. Its episodes are kept as standalone videos (courseId
/// cleared) so no uploaded video is lost by accident.
export const deleteCourse = onCall<{ courseId: string }>({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);
  const id = cleanDocId(request.data?.courseId, "courseId");
  const episodes = await db.collection("learnItems").where("courseId", "==", id).get();
  const batch = db.batch();
  episodes.docs.forEach((e) => batch.update(e.ref, { courseId: null, episodeNumber: null }));
  batch.delete(db.collection("courses").doc(id));
  await batch.commit();
  return { ok: true, unlinkedEpisodes: episodes.size };
});
