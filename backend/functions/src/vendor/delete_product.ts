import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db } from "../shared/firebase";
import { requireVendor } from "../shared/auth/require_role";

interface DeleteProductInput {
  productId: string;
}

export const deleteProduct = onCall<DeleteProductInput>({ region: "us-central1" }, async (request) => {
  const { vendorId } = requireVendor(request);
  const { productId } = request.data;

  if (!productId) {
    throw new HttpsError("invalid-argument", "productId is required.");
  }

  const productRef = db.collection("products").doc(productId);
  const snap = await productRef.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Product not found.");
  }
  if (snap.data()!.vendorId !== vendorId) {
    throw new HttpsError("permission-denied", "You don't own this product.");
  }

  await productRef.delete();
  return { ok: true };
});
