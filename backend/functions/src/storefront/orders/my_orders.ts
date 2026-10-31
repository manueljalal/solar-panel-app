import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db } from "../../shared/firebase";
import { cleanDocId, cleanText } from "../../shared/validation/sanitize";
import { serializeOrder, transitionOrder } from "../../shared/orders";

/// The caller's own orders, newest first. Equality-only query + in-memory
/// sort, so no composite index is needed.
export const listMyOrders = onCall({ region: "us-central1" }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required.");
  const snap = await db.collection("orders").where("uid", "==", request.auth.uid).orderBy("createdAt", "desc").limit(100).get();
  const orders = snap.docs.map((d) => serializeOrder(d)).sort((a, b) => (b.createdAt ?? 0) - (a.createdAt ?? 0));
  return { orders };
});

/// Customer cancels their own order — only while it is still 'placed'.
export const cancelMyOrder = onCall<{ orderId: string; reason?: string }>({ region: "us-central1" }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required.");
  const orderId = cleanDocId(request.data?.orderId, "orderId");
  const reason = cleanText(request.data?.reason, "reason", { max: 300 });
  await transitionOrder(orderId, "cancelled", { role: "customer", uid: request.auth.uid }, reason);
  return { ok: true };
});
