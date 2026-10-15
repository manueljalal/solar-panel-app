import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db } from "../shared/firebase";
import { requireVendor } from "../shared/auth/require_role";
import { changeOrderStatus, parseStatus, serializeOrder } from "../shared/orders/order_store";
import { cleanDocId, cleanText } from "../shared/validation/sanitize";

interface ListOrdersInput {
  status?: string;
}

/// Vendor-only: orders placed with the caller's business, newest first,
/// optionally filtered by status. Includes the customer's contact phone
/// and delivery address — the vendor needs them to arrange installation.
export const listOrders = onCall<ListOrdersInput>({ region: "us-central1" }, async (request) => {
  const { vendorId } = requireVendor(request);
  let query = db.collection("orders").where("vendorId", "==", vendorId);
  if (request.data?.status) query = query.where("status", "==", parseStatus(request.data.status));
  const snap = await query.orderBy("createdAt", "desc").limit(200).get();
  return { orders: snap.docs.map(serializeOrder) };
});

interface UpdateOrderStatusInput {
  orderId: string;
  status: string;
  note?: string;
}

/// Vendor-only: move one of the caller's own orders one step forward
/// (placed → confirmed → installation_scheduled → installer_en_route), or
/// cancel it before dispatch. The final "installed_verified" step belongs to
/// the customer (or an admin) — see shared/orders/status.ts.
export const updateOrderStatus = onCall<UpdateOrderStatusInput>({ region: "us-central1" }, async (request) => {
  const { uid, vendorId } = requireVendor(request);
  const orderId = cleanDocId(request.data?.orderId, "orderId");
  const to = parseStatus(request.data?.status);
  const note = cleanText(request.data?.note, "note", { max: 500, multiline: true });

  await changeOrderStatus({
    orderId,
    to,
    actor: "vendor",
    actorUid: uid,
    note,
    authorize: (order) => {
      if (order.vendorId !== vendorId) throw new HttpsError("not-found", "Order not found.");
    },
  });
  return { ok: true };
});
