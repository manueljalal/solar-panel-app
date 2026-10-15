import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { requireVendor } from "../shared/auth/require_role";
import { isOwnedImageUrl } from "../shared/images/store_image";
import { cleanDocId, cleanEnum, cleanLocalized, cleanPrice, cleanText, type LocalizedText } from "../shared/validation/sanitize";

interface CreateProductInput {
  /** Slug of a document in `categories` (admin-managed). */
  category: string;
  brand: string;
  /** Product name in Kurdish, Arabic and English. */
  name: LocalizedText;
  spec: string;
  wattage?: number;
  price: number;
  currency: "USD" | "IQD";
  imageUrl: string;
  /** Optional, but all three languages or none. */
  description?: LocalizedText;
  warranty?: LocalizedText;
}

/// Vendor-only. This is the actual "upload a product" operation — the
/// piece that was completely missing before: every product in Firestore
/// until now came from a one-off seed script, not from a real vendor.
export const createProduct = onCall<CreateProductInput>({ region: "us-central1" }, async (request) => {
  const { vendorId } = requireVendor(request);
  const input = request.data ?? ({} as CreateProductInput);

  const category = cleanDocId(input.category, "category");
  if (!(await db.collection("categories").doc(category).get()).exists) {
    throw new HttpsError("invalid-argument", "Choose a category from the list.");
  }

  const brand = cleanText(input.brand, "brand", { max: 80, min: 1 });
  const name = cleanLocalized(input.name, "Product name", { max: 120 });
  const spec = cleanText(input.spec, "spec", { max: 120 });
  const description = cleanLocalized(input.description, "Description", { max: 2000, multiline: true, optional: true });
  const warranty = cleanLocalized(input.warranty, "Warranty", { max: 120, optional: true });
  const price = cleanPrice(input.price);
  const currency = cleanEnum(input.currency ?? "USD", ["USD", "IQD"] as const, "currency");

  let wattage: number | null = null;
  if (input.wattage !== undefined && input.wattage !== null) {
    if (!Number.isInteger(input.wattage) || input.wattage <= 0 || input.wattage > 1_000_000) {
      throw new HttpsError("invalid-argument", "wattage must be a positive whole number.");
    }
    wattage = input.wattage;
  }

  if (!isOwnedImageUrl(input.imageUrl, `productImages/${vendorId}`)) {
    throw new HttpsError("invalid-argument", "Upload a product image first.");
  }

  const productRef = db.collection("products").doc();
  await productRef.set({
    vendorId,
    category,
    brand,
    // `name`/`description`/`warranty` stay plain English strings so existing
    // readers (mobile storefront) keep working; the full ku/ar/en set lives
    // in the *I18n fields.
    name: name.en,
    nameI18n: name,
    spec,
    wattage,
    price,
    currency,
    inStock: true,
    rating: 0,
    sold: 0,
    warranty: warranty?.en ?? null,
    warrantyI18n: warranty,
    description: description?.en ?? null,
    descriptionI18n: description,
    imageUrl: input.imageUrl,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  return { productId: productRef.id };
});
