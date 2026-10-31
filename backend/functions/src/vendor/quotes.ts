import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { requireVendor } from "../shared/auth/require_role";
import { cleanDocId, cleanEnum } from "../shared/validation/sanitize";
import { QUOTE_STATUSES, serializeQuote } from "../shared/quotes";

/// Quote requests shoppers sent for this vendor's products, newest first.
export const listQuoteRequests = onCall({ region: "us-central1" }, async (request) => {
  const { vendorId } = requireVendor(request);
  const snap = await db.collection("quoteRequests").where("vendorId", "==", vendorId).orderBy("createdAt", "desc").limit(300).get();
  const requests = snap.docs.map(serializeQuote).sort((a, b) => (b.createdAt ?? 0) - (a.createdAt ?? 0));
  return { requests };
});

/// Vendor marks a request as contacted / closed.
export const updateQuoteRequest = onCall<{ id: string; status: string }>({ region: "us-central1" }, async (request) => {
  const { vendorId } = requireVendor(request);
  const id = cleanDocId(request.data?.id, "id");
  const status = cleanEnum(request.data?.status, QUOTE_STATUSES, "status");
  const ref = db.collection("quoteRequests").doc(id);
  const snap = await ref.get();
  if (!snap.exists || snap.data()?.vendorId !== vendorId) throw new HttpsError("not-found", "Request not found.");
  await ref.update({ status, updatedAt: FieldValue.serverTimestamp() });
  return { ok: true };
});
