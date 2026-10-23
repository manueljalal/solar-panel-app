import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../../shared/firebase";
import { cleanDocId } from "../../shared/validation/sanitize";

/// The customer who placed an order can cancel it until a vendor/admin has
/// confirmed it — after that, cancelling goes through support (admin).
/// Runs in a transaction so a cancel can't race an admin confirming the
/// same order.
export const cancelOrder = onCall<{ orderId: string }>({ region: "us-central1" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const uid = request.auth.uid;
  const orderId = cleanDocId(request.data?.orderId, "orderId");
  const orderRef = db.collection("orders").doc(orderId);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(orderRef);
    const data = snap.data();
    // Same error for "doesn't exist" and "isn't yours" — don't confirm
    // that someone else's order id is valid.
    if (!snap.exists || !data || data.uid !== uid) {
      throw new HttpsError("not-found", "Order not found.");
    }
    if (data.status !== "placed") {
      throw new HttpsError("failed-precondition", "This order has already been confirmed — contact support to cancel it.");
    }
    tx.update(orderRef, {
      status: "cancelled",
      statusHistory: FieldValue.arrayUnion({ status: "cancelled", at: new Date(), by: "customer" }),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return { ok: true as const };
});
