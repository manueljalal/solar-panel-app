import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { requireVendor } from "../shared/auth/require_role";
import { serializeDoc } from "../shared/orders/order_store";
import { cleanDocId, cleanEnum, cleanPrice, cleanText } from "../shared/validation/sanitize";

/// Vendor-only: quote requests customers sent about the caller's products,
/// newest first.
export const listQuoteRequests = onCall({ region: "us-central1" }, async (request) => {
  const { vendorId } = requireVendor(request);
  const snap = await db
    .collection("quoteRequests")
    .where("vendorId", "==", vendorId)
    .orderBy("createdAt", "desc")
    .limit(200)
    .get();
  return { requests: snap.docs.map((d) => serializeDoc(d.id, d.data())) };
});

interface RespondInput {
  requestId: string;
  action: "quote" | "decline";
  /** Required for "quote". */
  price?: number;
  currency?: "USD" | "IQD";
  message?: string;
}

/// Vendor-only: answer a quote request with a price (and message), or
/// decline it. The customer sees the answer in the app's Account → My
/// quotes (storefront-listMyQuoteRequests). A vendor can revise its answer.
export const respondToQuoteRequest = onCall<RespondInput>({ region: "us-central1" }, async (request) => {
  const { uid, vendorId } = requireVendor(request);
  const requestId = cleanDocId(request.data?.requestId, "requestId");
  const action = cleanEnum(request.data?.action, ["quote", "decline"] as const, "action");
  const message = cleanText(request.data?.message, "message", { max: 1000, multiline: true });

  let response: Record<string, unknown>;
  if (action === "quote") {
    response = {
      price: cleanPrice(request.data?.price),
      currency: cleanEnum(request.data?.currency ?? "USD", ["USD", "IQD"] as const, "currency"),
      message,
    };
  } else {
    response = { price: null, currency: null, message };
  }

  const ref = db.collection("quoteRequests").doc(requestId);
  const snap = await ref.get();
  if (!snap.exists || snap.data()!.vendorId !== vendorId) {
    throw new HttpsError("not-found", "Quote request not found.");
  }

  await ref.update({
    status: action === "quote" ? "responded" : "declined",
    response: { ...response, respondedBy: uid, respondedAt: FieldValue.serverTimestamp() },
    updatedAt: FieldValue.serverTimestamp(),
  });
  return { ok: true };
});
