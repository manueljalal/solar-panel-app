import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db } from "../../shared/firebase";
import { changeOrderStatus, parseStatus, serializeOrder } from "../../shared/orders/order_store";
import { cleanDocId, cleanText } from "../../shared/validation/sanitize";

function requireUid(auth: { uid: string } | undefined): string {
  if (!auth) throw new HttpsError("unauthenticated", "Sign in required.");
  return auth.uid;
}

/// The caller's own orders, newest first. Orders aren't client-readable in
/// firestore.rules (they carry the vendor's and customer's contact
/// details), so this callable is the customer's only read path.
export const listMyOrders = onCall({ region: "us-central1" }, async (request) => {
  const uid = requireUid(request.auth);
  const snap = await db
    .collection("orders")
    .where("customerId", "==", uid)
    .orderBy("createdAt", "desc")
    .limit(100)
    .get();
  return { orders: snap.docs.map(serializeOrder) };
});

interface UpdateMyOrderInput {
  orderId: string;
  /// "cancelled" (only while still placed) or "installed_verified" (only
  /// once the installer is on the way) — see canTransition.
  status: string;
  note?: string;
}

/// Customer-side status changes: cancel before the vendor confirms, or
/// confirm the installation was done.
export const updateMyOrder = onCall<UpdateMyOrderInput>({ region: "us-central1" }, async (request) => {
  const uid = requireUid(request.auth);
  const orderId = cleanDocId(request.data?.orderId, "orderId");
  const to = parseStatus(request.data?.status);
  const note = cleanText(request.data?.note, "note", { max: 500, multiline: true });

  await changeOrderStatus({
    orderId,
    to,
    actor: "customer",
    actorUid: uid,
    note,
    authorize: (order) => {
      if (order.customerId !== uid) throw new HttpsError("not-found", "Order not found.");
    },
  });
  return { ok: true };
});
