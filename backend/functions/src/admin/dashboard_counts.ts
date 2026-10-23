import { onCall } from "firebase-functions/v2/https";
import { db } from "../shared/firebase";
import { requireRole } from "../shared/auth/require_role";

/// Admin-only. Dashboard tile numbers via count() aggregations — each is
/// billed as one read per 1,000 matches and returns no documents, unlike
/// listing every application just to take .length (which also capped the
/// numbers at the list limit of 100).
export const dashboardCounts = onCall({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);

  const applications = db.collection("vendorApplications");
  const [pending, approved, rejected, newOrders] = await Promise.all([
    applications.where("status", "==", "pending").count().get(),
    applications.where("status", "==", "approved").count().get(),
    applications.where("status", "==", "rejected").count().get(),
    db.collection("orders").where("status", "==", "placed").count().get(),
  ]);

  return {
    pending: pending.data().count,
    approved: approved.data().count,
    rejected: rejected.data().count,
    newOrders: newOrders.data().count,
  };
});
