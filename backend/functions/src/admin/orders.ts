import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { requireRole } from "../shared/auth/require_role";
import { changeOrderStatus, parseStatus, serializeDoc, serializeOrder } from "../shared/orders/order_store";
import { cleanDocId, cleanEnum, cleanText } from "../shared/validation/sanitize";

interface ListOrdersInput {
  status?: string;
  vendorId?: string;
}

/// Admin-only: platform-wide orders, newest first, optionally filtered by
/// status and/or vendor.
export const listOrders = onCall<ListOrdersInput>({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);
  let query: FirebaseFirestore.Query = db.collection("orders");
  if (request.data?.vendorId) query = query.where("vendorId", "==", cleanDocId(request.data.vendorId, "vendorId"));
  if (request.data?.status) query = query.where("status", "==", parseStatus(request.data.status));
  const snap = await query.orderBy("createdAt", "desc").limit(200).get();
  return { orders: snap.docs.map(serializeOrder) };
});

interface UpdateOrderStatusInput {
  orderId: string;
  status: string;
  note?: string;
}

/// Admin-only: support override — any status change out of a non-final
/// state (see canTransition's super_admin branch).
export const updateOrderStatus = onCall<UpdateOrderStatusInput>({ region: "us-central1" }, async (request) => {
  const { uid } = requireRole(request, ["super_admin"]);
  await changeOrderStatus({
    orderId: cleanDocId(request.data?.orderId, "orderId"),
    to: parseStatus(request.data?.status),
    actor: "super_admin",
    actorUid: uid,
    note: cleanText(request.data?.note, "note", { max: 500, multiline: true }),
    authorize: () => {},
  });
  return { ok: true };
});

/// Admin-only: disputes, open ones first then newest. Sorted in memory —
/// the volume is small and it avoids another composite index.
export const listDisputes = onCall<{ status?: string }>({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);
  let query: FirebaseFirestore.Query = db.collection("disputes");
  if (request.data?.status) {
    query = query.where("status", "==", cleanEnum(request.data.status, ["open", "resolved", "rejected"] as const, "status"));
  }
  const snap = await query.limit(300).get();
  const disputes = snap.docs
    .map((d) => serializeDoc(d.id, d.data()))
    .sort((a, b) => {
      if ((a.status === "open") !== (b.status === "open")) return a.status === "open" ? -1 : 1;
      return ((b.createdAt as number) ?? 0) - ((a.createdAt as number) ?? 0);
    });
  return { disputes };
});

interface ResolveDisputeInput {
  disputeId: string;
  outcome: "resolved" | "rejected";
  resolution: string;
  /** Also cancel the underlying order (when it isn't already final). */
  cancelOrder?: boolean;
}

/// Admin-only: close a dispute with a written resolution the customer sees
/// on the order, optionally cancelling the order in the same step.
export const resolveDispute = onCall<ResolveDisputeInput>({ region: "us-central1" }, async (request) => {
  const { uid } = requireRole(request, ["super_admin"]);
  const disputeId = cleanDocId(request.data?.disputeId, "disputeId");
  const outcome = cleanEnum(request.data?.outcome, ["resolved", "rejected"] as const, "outcome");
  const resolution = cleanText(request.data?.resolution, "resolution", { max: 2000, min: 3, multiline: true });

  const disputeRef = db.collection("disputes").doc(disputeId);
  const dispute = (await disputeRef.get()).data();
  if (!dispute) throw new HttpsError("not-found", "Dispute not found.");
  if (dispute.status !== "open") throw new HttpsError("failed-precondition", "This dispute is already closed.");

  if (request.data?.cancelOrder === true) {
    await changeOrderStatus({
      orderId: dispute.orderId,
      to: "cancelled",
      actor: "super_admin",
      actorUid: uid,
      note: `Dispute: ${resolution}`,
      authorize: () => {},
    });
  }

  const batch = db.batch();
  batch.update(disputeRef, {
    status: outcome,
    resolution,
    resolvedBy: uid,
    resolvedAt: FieldValue.serverTimestamp(),
  });
  batch.update(db.collection("orders").doc(dispute.orderId), {
    disputeStatus: outcome,
    disputeResolution: resolution,
    updatedAt: FieldValue.serverTimestamp(),
  });
  await batch.commit();
  return { ok: true };
});
