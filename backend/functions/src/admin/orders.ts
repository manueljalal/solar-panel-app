import { onCall } from "firebase-functions/v2/https";
import { db } from "../shared/firebase";
import { requireRole } from "../shared/auth/require_role";
import { cleanDocId, cleanEnum, cleanText } from "../shared/validation/sanitize";
import { ORDER_STATUSES, serializeOrder, transitionOrder } from "../shared/orders";

/// Admin: newest orders across all vendors (single-field createdAt order,
/// no composite index), optionally filtered by status.
export const listOrders = onCall<{ status?: string }>({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);
  const status = request.data?.status ? cleanEnum(request.data.status, ORDER_STATUSES, "status") : null;
  const snap = await db.collection("orders").orderBy("createdAt", "desc").limit(500).get();
  const orders = snap.docs.map((d) => serializeOrder(d, { includeUid: true })).filter((o) => !status || o.status === status);
  return { orders };
});

/// Admin override for stuck orders — same transition rules as vendors.
export const updateOrderStatus = onCall<{ orderId: string; status: string; reason?: string }>(
  { region: "us-central1" },
  async (request) => {
    const { uid } = requireRole(request, ["super_admin"]);
    const orderId = cleanDocId(request.data?.orderId, "orderId");
    const status = cleanEnum(request.data?.status, ORDER_STATUSES, "status");
    const reason = cleanText(request.data?.reason, "reason", { max: 300 });
    await transitionOrder(orderId, status, { role: "super_admin", uid }, reason);
    return { ok: true };
  },
);
