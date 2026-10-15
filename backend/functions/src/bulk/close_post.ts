import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { cleanDocId, cleanEnum } from "../shared/validation/sanitize";
import { requireBulkVendor } from "./shared";

interface ClosePostInput {
  kind: "listing" | "request";
  id: string;
}

/// Owner-only. Takes one of the caller's posts off the marketplace
/// (listing sold out / request filled). Soft close — the doc is kept.
export const closePost = onCall<ClosePostInput>({ region: "us-central1" }, async (request) => {
  const me = await requireBulkVendor(request);
  const kind = cleanEnum(request.data?.kind, ["listing", "request"] as const, "kind");
  const id = cleanDocId(request.data?.id, "id");

  const ref = db.collection(kind === "listing" ? "bulkListings" : "bulkRequests").doc(id);
  const snap = await ref.get();
  if (!snap.exists || snap.data()?.vendorId !== me.vendorId) {
    throw new HttpsError("not-found", "Post not found.");
  }
  await ref.update({ status: "closed", closedAt: FieldValue.serverTimestamp() });
  return { ok: true };
});
