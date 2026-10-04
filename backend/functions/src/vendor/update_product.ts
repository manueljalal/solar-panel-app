import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { requireVendor } from "../shared/auth/require_role";

interface UpdateProductInput {
  productId: string;
  patch: Partial<{
    brand: string;
    name: string;
    spec: string;
    wattage: number | null;
    price: number;
    currency: "USD" | "IQD";
    imageUrl: string;
    description: string | null;
    warranty: string | null;
    inStock: boolean;
  }>;
}

const EDITABLE_FIELDS = new Set([
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

  const productRef = db.collection("products").doc(productId);
  const snap = await productRef.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Product not found.");
  }
  if (snap.data()!.vendorId !== vendorId) {
    throw new HttpsError("permission-denied", "You don't own this product.");
  }

  await productRef.update({ ...patch, updatedAt: FieldValue.serverTimestamp() });
  return { ok: true };
});
