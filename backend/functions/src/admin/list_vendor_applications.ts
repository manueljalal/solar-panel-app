import { onCall } from "firebase-functions/v2/https";
import { db } from "../shared/firebase";
import { requireRole } from "../shared/auth/require_role";

interface ListInput {
  status?: "pending" | "approved" | "rejected";
}

/// Admin-only. Firestore rules deny direct client reads of
/// vendorApplications outside the submitter's own doc, so the admin
/// panel goes through this callable rather than a client-side query.
export const listVendorApplications = onCall<ListInput>({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);

  const status = request.data?.status ?? "pending";
  const snap = await db
    .collection("vendorApplications")
    .where("status", "==", status)
    .orderBy("createdAt", "desc")
    .limit(100)
    .get();

  return {
    applications: snap.docs.map((d) => ({ id: d.id, ...d.data() })),
  };
});
