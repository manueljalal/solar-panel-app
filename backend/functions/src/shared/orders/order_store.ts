import { HttpsError } from "firebase-functions/v2/https";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "../firebase";
import { canTransition, ORDER_STATUSES, type OrderActor, type OrderStatus } from "./status";

/// Firestore Timestamps don't survive the callable transport as anything
/// useful (they arrive as {_seconds, _nanoseconds}); every callable that
/// returns stored docs converts them to epoch millis first.
export function toMillis(value: unknown): number | null {
  if (value instanceof Timestamp) return value.toMillis();
  if (value instanceof Date) return value.getTime();
  return null;
}

export function serializeDoc(id: string, data: FirebaseFirestore.DocumentData): Record<string, unknown> {
  const out: Record<string, unknown> = { id };
  for (const [key, value] of Object.entries(data)) {
    if (value instanceof Timestamp || value instanceof Date) {
      out[key] = toMillis(value);
    } else if (Array.isArray(value)) {
      out[key] = value.map((v) =>
        v && typeof v === "object" && !Array.isArray(v) ? serializeDoc("", v as FirebaseFirestore.DocumentData) : v,
      );
    } else if (value && typeof value === "object") {
      const nested = serializeDoc("", value as FirebaseFirestore.DocumentData);
      delete nested.id;
      out[key] = nested;
    } else {
      out[key] = value;
    }
  }
  return out;
}

export function serializeOrder(snap: FirebaseFirestore.DocumentSnapshot): Record<string, unknown> {
  const out = serializeDoc(snap.id, snap.data() ?? {});
  // Nested history entries got an empty id from serializeDoc — drop it.
  if (Array.isArray(out.statusHistory)) {
    out.statusHistory = (out.statusHistory as Record<string, unknown>[]).map(({ id: _id, ...rest }) => rest);
  }
  if (Array.isArray(out.items)) {
    out.items = (out.items as Record<string, unknown>[]).map(({ id: _id, ...rest }) => rest);
  }
  return out;
}

export function parseStatus(value: unknown): OrderStatus {
  if (typeof value !== "string" || !(ORDER_STATUSES as readonly string[]).includes(value)) {
    throw new HttpsError("invalid-argument", `status must be one of: ${ORDER_STATUSES.join(", ")}.`);
  }
  return value as OrderStatus;
}

interface ChangeStatusInput {
  orderId: string;
  to: OrderStatus;
  actor: OrderActor;
  actorUid: string;
  note?: string;
  /// Throws if the caller isn't allowed to touch THIS order (ownership).
  authorize: (order: FirebaseFirestore.DocumentData) => void;
}

/// The one place an order's status changes. Runs in a transaction so two
/// actors (e.g. customer cancelling while the vendor confirms) can't both
/// win, appends to statusHistory, and — when an installation is verified —
/// counts the sale on each product (`sold` drives "Best sellers").
export async function changeOrderStatus({ orderId, to, actor, actorUid, note, authorize }: ChangeStatusInput) {
  const ref = db.collection("orders").doc(orderId);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "Order not found.");
    const order = snap.data()!;
    authorize(order);

    const from = order.status as OrderStatus;
    if (!canTransition(actor, from, to)) {
      throw new HttpsError("failed-precondition", `Can't move this order from '${from}' to '${to}'.`);
    }

    // Transactions need every read before any write.
    const items = (order.items ?? []) as { productId: string; quantity: number }[];
    const productSnaps =
      to === "installed_verified" && items.length > 0
        ? await tx.getAll(...items.map((i) => db.collection("products").doc(i.productId)))
        : [];

    tx.update(ref, {
      status: to,
      updatedAt: FieldValue.serverTimestamp(),
      statusHistory: FieldValue.arrayUnion({
        status: to,
        at: Timestamp.now(),
        by: actor,
        byUid: actorUid,
        note: note ?? "",
      }),
      ...(to === "cancelled" ? { cancelledBy: actor } : {}),
    });

    // A product deleted since the order was placed is skipped, not
    // re-created as a stub.
    productSnaps.forEach((p, i) => {
      if (p.exists) tx.update(p.ref, { sold: FieldValue.increment(items[i].quantity) });
    });
    return { from, to };
  });
}
