import { HttpsError } from "firebase-functions/v2/https";
import { FieldValue, Timestamp, type DocumentSnapshot } from "firebase-admin/firestore";
import { db } from "./firebase";

import { ORDER_STATUSES, transitionError, type OrderStatus } from "./order_rules";

export { ORDER_STATUSES, type OrderStatus };

export type OrderActor =
  | { role: "customer"; uid: string }
  | { role: "vendor"; uid: string; vendorId: string }
  | { role: "super_admin"; uid: string };


export interface OrderItem {
  productId: string;
  name: string;
  imageUrl: string;
  unitPrice: number;
  currency: string;
  qty: number;
  lineTotal: number;
}

/// Firestore order doc -> JSON for the callable response (timestamps as
/// epoch millis; the customer's internal uid is not exposed to vendors).
export function serializeOrder(snap: DocumentSnapshot, opts: { includeUid?: boolean } = {}) {
  const d = snap.data() ?? {};
  const millis = (t: unknown) => (t instanceof Timestamp ? t.toMillis() : null);
  return {
    id: snap.id,
    ...(opts.includeUid ? { uid: d.uid } : {}),
    vendorId: d.vendorId,
    vendorName: d.vendorName ?? "",
    customerName: d.customerName ?? "",
    customerPhone: d.customerPhone ?? "",
    items: (d.items ?? []) as OrderItem[],
    totals: (d.totals ?? {}) as Record<string, number>,
    paymentMethod: d.paymentMethod ?? "cod",
    address: d.address ?? "",
    location: d.location ?? null,
    note: d.note ?? "",
    status: d.status as OrderStatus,
    cancelReason: d.cancelReason ?? null,
    statusHistory: ((d.statusHistory ?? []) as { status: string; at: Timestamp; by: string }[]).map((h) => ({
      status: h.status,
      at: millis(h.at),
      by: h.by,
    })),
    createdAt: millis(d.createdAt),
    updatedAt: millis(d.updatedAt),
  };
}

/// Moves an order to [next] if [actor] may, inside a transaction so two
/// people acting at once can't skip or repeat a step. Delivering an order
/// adds its quantities to each product's `sold` counter.
export async function transitionOrder(
  orderId: string,
  next: OrderStatus,
  actor: OrderActor,
  reason?: string,
): Promise<void> {
  const ref = db.collection("orders").doc(orderId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const order = snap.data();
    if (!snap.exists || !order) throw new HttpsError("not-found", "Order not found.");

    if (actor.role === "customer" && order.uid !== actor.uid) throw new HttpsError("not-found", "Order not found.");
    if (actor.role === "vendor" && order.vendorId !== actor.vendorId) throw new HttpsError("not-found", "Order not found.");

    const problem = transitionError(order.status as OrderStatus, next, actor.role);
    if (problem) {
      throw new HttpsError(problem.startsWith("An order") ? "failed-precondition" : "permission-denied", problem);
    }

    const update: Record<string, unknown> = {
      status: next,
      updatedAt: FieldValue.serverTimestamp(),
      statusHistory: FieldValue.arrayUnion({ status: next, at: Timestamp.now(), by: actor.role }),
    };
    if (next === "cancelled") update.cancelReason = reason || null;
    if (next === "delivered") {
      update.deliveredAt = FieldValue.serverTimestamp();
      for (const item of (order.items ?? []) as OrderItem[]) {
        tx.update(db.collection("products").doc(item.productId), { sold: FieldValue.increment(item.qty) });
      }
    }
    tx.update(ref, update);
  });
}
