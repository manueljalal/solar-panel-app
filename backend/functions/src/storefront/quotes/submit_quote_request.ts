import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../../shared/firebase";
import { cleanDocId, cleanText } from "../../shared/validation/sanitize";

interface SubmitQuoteRequestInput {
  productId: string;
  note: string;
}

/// A shopper asks a vendor for a price on one product (bulk quantity,
/// installation, site address...). Needs a real account: the vendor answers
/// by calling the verified phone. Product name and vendor are read from the
/// product doc, never trusted from the client, so the request lands in that
/// vendor's inbox (vendor-listQuoteRequests).
export const submitQuoteRequest = onCall<SubmitQuoteRequestInput>({ region: "us-central1" }, async (request) => {
  const auth = request.auth;
  if (!auth) throw new HttpsError("unauthenticated", "Sign in required.");
  if (auth.token.firebase?.sign_in_provider === "anonymous") {
    throw new HttpsError("failed-precondition", "Create an account to request a quote.");
  }

  const productId = cleanDocId(request.data?.productId, "productId");
  const note = cleanText(request.data?.note, "note", { max: 1000, multiline: true });

  const product = (await db.collection("products").doc(productId).get()).data();
  if (!product?.vendorId) throw new HttpsError("not-found", "This product is no longer available.");
  const [vendor, user] = await Promise.all([
    db.collection("vendors").doc(product.vendorId).get(),
    db.collection("users").doc(auth.uid).get(),
  ]);

  const ref = db.collection("quoteRequests").doc();
  await ref.set({
    uid: auth.uid,
    customerName: user.data()?.name ?? "",
    customerPhone: user.data()?.phone ?? "",
    productId,
    productTitle: product.name ?? "",
    productImageUrl: product.imageUrl ?? "",
    vendorId: product.vendorId,
    vendorName: vendor.data()?.businessName ?? "",
    note,
    status: "new",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return { requestId: ref.id };
});
