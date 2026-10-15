import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../../shared/firebase";
import { addRating } from "../../shared/orders/status";
import { cleanDocId, cleanText } from "../../shared/validation/sanitize";

interface SubmitReviewInput {
  orderId: string;
  productId: string;
  rating: number;
  comment?: string;
}

/// Verified-purchase reviews only: the caller must own the order, the
/// installation must be confirmed (installed_verified), and the product
/// must be on that order. One review per order line — the doc id is
/// `${orderId}_${productId}`, so a retry can't double-count.
///
/// Updates the running average on the product and on its vendor in the
/// same transaction; the storefront sorts companies by `rating`.
export const submitReview = onCall<SubmitReviewInput>({ region: "us-central1" }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required.");
  const uid = request.auth.uid;
  const orderId = cleanDocId(request.data?.orderId, "orderId");
  const productId = cleanDocId(request.data?.productId, "productId");
  const rating = request.data?.rating;
  if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
    throw new HttpsError("invalid-argument", "rating must be a whole number from 1 to 5.");
  }
  const comment = cleanText(request.data?.comment, "comment", { max: 1000, multiline: true });

  const userSnap = await db.collection("users").doc(uid).get();
  const reviewerName = (userSnap.data()?.name as string | undefined)?.split(" ")[0] ?? "";

  const orderRef = db.collection("orders").doc(orderId);
  const reviewRef = db.collection("reviews").doc(`${orderId}_${productId}`);
  const productRef = db.collection("products").doc(productId);

  await db.runTransaction(async (tx) => {
    const [orderSnap, reviewSnap, productSnap] = await tx.getAll(orderRef, reviewRef, productRef);
    const order = orderSnap.data();
    if (!orderSnap.exists || !order || order.customerId !== uid) {
      throw new HttpsError("not-found", "Order not found.");
    }
    if (order.status !== "installed_verified") {
      throw new HttpsError("failed-precondition", "You can review a product once its installation is confirmed.");
    }
    if (!((order.items ?? []) as { productId: string }[]).some((i) => i.productId === productId)) {
      throw new HttpsError("invalid-argument", "That product isn't part of this order.");
    }
    if (reviewSnap.exists) {
      throw new HttpsError("already-exists", "You've already reviewed this product for this order.");
    }

    const vendorRef = db.collection("vendors").doc(order.vendorId as string);
    const vendorSnap = await tx.get(vendorRef);

    tx.create(reviewRef, {
      orderId,
      productId,
      vendorId: order.vendorId,
      customerId: uid,
      reviewerName: reviewerName || order.contact?.name?.split(" ")[0] || "",
      rating,
      comment,
      createdAt: FieldValue.serverTimestamp(),
    });

    if (productSnap.exists) {
      const p = productSnap.data()!;
      const next = addRating(p.rating ?? 0, p.reviewCount ?? 0, rating);
      tx.update(productRef, { rating: next.average, reviewCount: next.count });
    }
    if (vendorSnap.exists) {
      const v = vendorSnap.data()!;
      const next = addRating(v.rating ?? 0, v.reviewCount ?? 0, rating);
      tx.update(vendorRef, { rating: next.average, reviewCount: next.count });
    }
    tx.update(orderRef, { reviewedProductIds: FieldValue.arrayUnion(productId) });
  });

  return { ok: true };
});
