import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { requireRole } from "../shared/auth/require_role";
import { isOwnedImageUrl } from "../shared/images/store_image";
import { cleanDocId, cleanLocalized, type LocalizedText } from "../shared/validation/sanitize";

/// categories/{slug} -> { name: { ku, ar, en } }. The doc id is the slug,
/// derived once from the English name and never changed, so products can
/// reference it (products.category) without it shifting under them when a
/// name is later edited. Reads are public (Firestore rules) — the vendor
/// portal and storefront list categories directly; writes are admin-only
/// and go through these callables.

const MAX_CATEGORIES = 200;

function slugify(en: string): string {
  return en
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 60);
}

export const createCategory = onCall<{ name: LocalizedText; imageUrl: string }>({ region: "us-central1" }, async (request) => {
  const { uid } = requireRole(request, ["super_admin"]);
  const name = cleanLocalized(request.data?.name, "Category name");
  const imageUrl = request.data?.imageUrl;
  if (!isOwnedImageUrl(imageUrl, "categoryImages")) {
    throw new HttpsError("invalid-argument", "Upload a category image.");
  }

  const slug = slugify(name.en);
  if (!slug) {
    throw new HttpsError("invalid-argument", "English name must contain letters or numbers.");
  }

  const ref = db.collection("categories").doc(slug);
  await db.runTransaction(async (tx) => {
    if ((await tx.get(ref)).exists) {
      throw new HttpsError("already-exists", "A category with this English name already exists.");
    }
    tx.set(ref, { name, imageUrl, createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(), createdBy: uid });
  });
  // Cheap guard against runaway creation; checked after so a race can only
  // overshoot by a handful, which is harmless.
  const count = await db.collection("categories").count().get();
  if (count.data().count > MAX_CATEGORIES) {
    await ref.delete();
    throw new HttpsError("resource-exhausted", `At most ${MAX_CATEGORIES} categories.`);
  }
  return { categoryId: slug };
});

export const updateCategory = onCall<{ categoryId: string; name: LocalizedText; imageUrl?: string }>(
  { region: "us-central1" },
  async (request) => {
    requireRole(request, ["super_admin"]);
    const categoryId = cleanDocId(request.data?.categoryId, "categoryId");
    const name = cleanLocalized(request.data?.name, "Category name");
    // Optional on update: omitted = keep the current image.
    const imageUrl = request.data?.imageUrl;
    if (imageUrl !== undefined && !isOwnedImageUrl(imageUrl, "categoryImages")) {
      throw new HttpsError("invalid-argument", "Upload a category image.");
    }

    const ref = db.collection("categories").doc(categoryId);
    if (!(await ref.get()).exists) {
      throw new HttpsError("not-found", "Category not found.");
    }
    await ref.update({ name, ...(imageUrl ? { imageUrl } : {}), updatedAt: FieldValue.serverTimestamp() });
    return { ok: true };
  },
);

export const deleteCategory = onCall<{ categoryId: string }>({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);
  const categoryId = cleanDocId(request.data?.categoryId, "categoryId");

  const inUse = await db.collection("products").where("category", "==", categoryId).limit(1).get();
  if (!inUse.empty) {
    throw new HttpsError("failed-precondition", "Products still use this category — it can't be deleted.");
  }
  await db.collection("categories").doc(categoryId).delete();
  return { ok: true };
});
