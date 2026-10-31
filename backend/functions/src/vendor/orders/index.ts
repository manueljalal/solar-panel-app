import { onCall } from "firebase-functions/v2/https";
import { db } from "../../shared/firebase";
import { requireVendor } from "../../shared/auth/require_role";
import { cleanDocId, cleanEnum, cleanText } from "../../shared/validation/sanitize";
import { ORDER_STATUSES, serializeOrder, transitionOrder } from "../../shared/orders";

/// The calling vendor's orders, newest first, optionally one status.
export const listOrders = onCall<{ status?: string }>({ region: "us-central1" }, async (request) => {
  const { vendorId } = requireVendor(request);
  const status = request.data?.status ? cleanEnum(request.data.status, ORDER_STATUSES, "status") : null;
  const snap = await db.collection("orders").where("vendorId", "==", vendorId).orderBy("createdAt", "desc").limit(300).get();
  const orders = snap.docs
    .map((d) => serializeOrder(d))
    .filter((o) => !status || o.status === status)
    .sort((a, b) => (b.createdAt ?? 0) - (a.createdAt ?? 0));
  return { orders };
});

/// Vendor moves one of its orders along: confirm, dispatch, deliver, or
/// cancel (with a reason) before it's dispatched.
export const updateOrderStatus = onCall<{ orderId: string; status: string; reason?: string }>(
  { region: "us-central1" },
  async (request) => {
    const { uid, vendorId } = requireVendor(request);
    const orderId = cleanDocId(request.data?.orderId, "orderId");
    const status = cleanEnum(request.data?.status, ORDER_STATUSES, "status");
    const reason = cleanText(request.data?.reason, "reason", { max: 300 });
    await transitionOrder(orderId, status, { role: "vendor", uid, vendorId }, reason);
    return { ok: true };
  },
);
