import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../../shared/firebase";
import { cleanDocId, cleanText } from "../../shared/validation/sanitize";

interface OpenDisputeInput {
  orderId: string;
  reason: string;
}

/// A customer flags a problem with one of their orders for a super_admin to
/// look at (web admin → Disputes). One dispute per order — the doc id is
/// the order id — and it can be re-opened after a resolution.
export const openDispute = onCall<OpenDisputeInput>({ region: "us-central1" }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required.");
  const uid = request.auth.uid;
  const orderId = cleanDocId(request.data?.orderId, "orderId");
  const reason = cleanText(request.data?.reason, "reason", { max: 2000, min: 10, multiline: true });

  const orderRef = db.collection("orders").doc(orderId);
  const disputeRef = db.collection("disputes").doc(orderId);

  await db.runTransaction(async (tx) => {
    const [orderSnap, disputeSnap] = await tx.getAll(orderRef, disputeRef);
    const order = orderSnap.data();
    if (!orderSnap.exists || !order || order.customerId !== uid) {
      throw new HttpsError("not-found", "Order not found.");
    }
    if (disputeSnap.exists && disputeSnap.data()!.status === "open") {
      throw new HttpsError("already-exists", "There's already an open issue for this order.");
    }
    tx.set(disputeRef, {
      orderId,
      customerId: uid,
      vendorId: order.vendorId,
      vendorName: order.vendorName ?? "",
      customerName: order.contact?.name ?? "",
      customerPhone: order.contact?.phone ?? "",
      orderStatus: order.status,
      reason,
      status: "open",
      resolution: null,
      resolvedBy: null,
      resolvedAt: null,
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.update(orderRef, { disputeStatus: "open", updatedAt: FieldValue.serverTimestamp() });
  });

  return { ok: true };
});
