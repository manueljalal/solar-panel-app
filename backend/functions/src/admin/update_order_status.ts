import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { requireRole } from "../shared/auth/require_role";
import { assertTransition, ORDER_STATUSES, type OrderStatus } from "../shared/orders/order_status";
import { cleanDocId, cleanEnum } from "../shared/validation/sanitize";

/// Admin-only. Moves an order along placed → confirmed → shipped →
/// delivered, or cancels it. Marking an order delivered is also when each
/// product's `sold` counter goes up — counting at placement would inflate
/// "best sellers" with orders that later get cancelled.
export const updateOrderStatus = onCall<{ orderId: string; status: OrderStatus }>(
  { region: "us-central1" },
  async (request) => {
    const { uid } = requireRole(request, ["super_admin"]);
    const orderId = cleanDocId(request.data?.orderId, "orderId");
    const status = cleanEnum(request.data?.status, ORDER_STATUSES, "status");
    const orderRef = db.collection("orders").doc(orderId);

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(orderRef);
      const data = snap.data();
      if (!snap.exists || !data) {
        throw new HttpsError("not-found", "Order not found.");
      }
      assertTransition(data.status as OrderStatus, status);

      // Transactions need every read before the first write, so the
      // product lookups happen up front. A product deleted since the order
      // was placed is skipped rather than failing the status change.
      const soldUpdates: { ref: FirebaseFirestore.DocumentReference; quantity: number }[] = [];
      if (status === "delivered") {
        for (const item of (data.items ?? []) as { productId?: string; quantity?: number }[]) {
          if (!item.productId || !item.quantity) continue;
          const productRef = db.collection("products").doc(item.productId);
          if ((await tx.get(productRef)).exists) soldUpdates.push({ ref: productRef, quantity: item.quantity });
        }
      }

      tx.update(orderRef, {
        status,
        statusHistory: FieldValue.arrayUnion({ status, at: new Date(), by: uid }),
        updatedAt: FieldValue.serverTimestamp(),
      });
      for (const { ref, quantity } of soldUpdates) {
        tx.update(ref, { sold: FieldValue.increment(quantity) });
      }
    });

    return { ok: true as const };
  },
);
