import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { requireVendor } from "../shared/auth/require_role";
import { isOwnedImageUrl } from "../shared/images/store_image";
import { cleanDocId, cleanEnum, cleanLocalized, cleanPrice, cleanText, type LocalizedText } from "../shared/validation/sanitize";

interface UpdateProductInput {
  productId: string;
  patch: Partial<{
    category: string;
    brand: string;
    name: LocalizedText;
    spec: string;
    wattage: number | null;
    price: number;
    currency: "USD" | "IQD";
    imageUrl: string;
    description: LocalizedText | null;
    warranty: LocalizedText | null;
    inStock: boolean;
  }>;
}

const EDITABLE_FIELDS = new Set([
  "category",
  "brand",
  "name",
  "spec",
  "wattage",
  "price",
  "currency",
  "imageUrl",
  "description",
  "warranty",
  "inStock",
]);

/// Vendor-only, and only on products that vendor owns — this server-side
/// ownership check is why product writes go through a callable instead of
/// Firestore rules alone (a rule would need a get() per write to check
/// vendorId).
export const updateProduct = onCall<UpdateProductInput>({ region: "us-central1" }, async (request) => {
  const { vendorId } = requireVendor(request);
  const { productId, patch } = request.data;

  if (!productId || !patch || Object.keys(patch).length === 0) {
    throw new HttpsError("invalid-argument", "productId and a non-empty patch are required.");
  }

  const invalidKeys = Object.keys(patch).filter((k) => !EDITABLE_FIELDS.has(k));
  if (invalidKeys.length > 0) {
    throw new HttpsError("invalid-argument", `Not editable: ${invalidKeys.join(", ")}`);
  }

  const clean: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(patch)) {
    switch (key) {
      case "category": {
        const category = cleanDocId(value, "category");
        if (!(await db.collection("categories").doc(category).get()).exists) {
          throw new HttpsError("invalid-argument", "Choose a category from the list.");
        }
        clean.category = category;
        break;
      }
      case "brand":
        clean.brand = cleanText(value, "brand", { max: 80, min: 1 });
        break;
      case "name": {
        const name = cleanLocalized(value, "Product name", { max: 120 });
        clean.name = name.en;
        clean.nameI18n = name;
        break;
      }
      case "spec":
        clean.spec = cleanText(value, "spec", { max: 120 });
        break;
      case "description": {
        const d = cleanLocalized(value, "Description", { max: 2000, multiline: true, optional: true });
        clean.description = d?.en ?? null;
        clean.descriptionI18n = d;
        break;
      }
      case "warranty": {
        const w = cleanLocalized(value, "Warranty", { max: 120, optional: true });
        clean.warranty = w?.en ?? null;
        clean.warrantyI18n = w;
        break;
      }
      case "price":
        clean.price = cleanPrice(value);
        break;
      case "currency":
        clean.currency = cleanEnum(value, ["USD", "IQD"] as const, "currency");
        break;
      case "wattage":
        if (value !== null && (!Number.isInteger(value) || (value as number) <= 0 || (value as number) > 1_000_000)) {
          throw new HttpsError("invalid-argument", "wattage must be a positive whole number.");
        }
        clean.wattage = value;
        break;
      case "inStock":
        if (typeof value !== "boolean") throw new HttpsError("invalid-argument", "inStock must be true or false.");
        clean.inStock = value;
        break;
      case "imageUrl":
        if (!isOwnedImageUrl(value, `productImages/${vendorId}`)) {
          throw new HttpsError("invalid-argument", "Upload a product image first.");
        }
        clean.imageUrl = value;
        break;
    }
  }

  const productRef = db.collection("products").doc(cleanDocId(productId, "productId"));
  const snap = await productRef.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Product not found.");
  }
  if (snap.data()!.vendorId !== vendorId) {
    throw new HttpsError("permission-denied", "You don't own this product.");
  }

  await productRef.update({ ...clean, updatedAt: FieldValue.serverTimestamp() });
  return { ok: true };
});
