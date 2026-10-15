import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { requireRole } from "../shared/auth/require_role";
import { isOwnedImageUrl } from "../shared/images/store_image";
import { cleanDocId, cleanLocalized, type LocalizedText } from "../shared/validation/sanitize";

/// banners/{id} -> { imageUrl, title?: { ku, ar, en }, createdAt }. The
/// mobile home carousel reads this collection directly (public read in
/// Firestore rules); only a super_admin can change it, through these
/// callables. At most MAX_BANNERS exist at any time — enforced here, inside
/// a transaction, not just in the admin UI.
const MAX_BANNERS = 5;

/// Optional overlay shade behind the headline, as #RRGGBB. null = none.
function cleanOverlay(value: unknown): string | null {
  if (value === undefined || value === null || value === "") return null;
  if (typeof value !== "string" || !/^#[0-9a-fA-F]{6}$/.test(value)) {
    throw new HttpsError("invalid-argument", "Overlay color must look like #1F5A44.");
  }
  return value.toUpperCase();
}

interface BannerInput {
  /** Optional overlay color (#RRGGBB) shown as a gradient under the headline. */
  overlayColor?: string | null;
  imageUrl: string;
  /** Optional headline shown over the image — all three languages or none. */
  title?: LocalizedText | null;
}

export const createBanner = onCall<BannerInput>({ region: "us-central1" }, async (request) => {
  const { uid } = requireRole(request, ["super_admin"]);
  const imageUrl = request.data?.imageUrl;
  if (!isOwnedImageUrl(imageUrl, "bannerImages")) {
    throw new HttpsError("invalid-argument", "Upload a banner image.");
  }
  const title = cleanLocalized(request.data?.title, "Banner title", { max: 80, optional: true });
  const overlayColor = cleanOverlay(request.data?.overlayColor);

  const ref = db.collection("banners").doc();
  await db.runTransaction(async (tx) => {
    // The transaction re-runs if another banner is created concurrently, so
    // two simultaneous requests can't both slip past the limit.
    const existing = await tx.get(db.collection("banners").limit(MAX_BANNERS));
    if (existing.size >= MAX_BANNERS) {
      throw new HttpsError("failed-precondition", `You can have at most ${MAX_BANNERS} banners. Delete one first.`);
    }
    tx.set(ref, {
      imageUrl,
      title,
      overlayColor,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      createdBy: uid,
    });
  });
  return { bannerId: ref.id };
});

export const updateBanner = onCall<BannerInput & { bannerId: string }>({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);
  const bannerId = cleanDocId(request.data?.bannerId, "bannerId");
  const patch: Record<string, unknown> = { updatedAt: FieldValue.serverTimestamp() };

  if (request.data?.imageUrl !== undefined) {
    if (!isOwnedImageUrl(request.data.imageUrl, "bannerImages")) {
      throw new HttpsError("invalid-argument", "Upload a banner image.");
    }
    patch.imageUrl = request.data.imageUrl;
  }
  // `title` present (even null) means "set it"; absent means "leave it".
  if (request.data && "title" in request.data) {
    patch.title = cleanLocalized(request.data.title, "Banner title", { max: 80, optional: true });
  }

  if (request.data && "overlayColor" in request.data) {
    patch.overlayColor = cleanOverlay(request.data.overlayColor);
  }

  const ref = db.collection("banners").doc(bannerId);
  if (!(await ref.get()).exists) {
    throw new HttpsError("not-found", "Banner not found.");
  }
  await ref.update(patch);
  return { ok: true };
});

export const deleteBanner = onCall<{ bannerId: string }>({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);
  await db.collection("banners").doc(cleanDocId(request.data?.bannerId, "bannerId")).delete();
  return { ok: true };
});
