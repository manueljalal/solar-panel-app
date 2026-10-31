import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { requireVendor } from "../shared/auth/require_role";
import { cleanDocId, cleanEnum } from "../shared/validation/sanitize";
import { serializeServiceRequest } from "../shared/services";

/// Service jobs an admin assigned to this vendor, newest first.
export const listServiceJobs = onCall({ region: "us-central1" }, async (request) => {
  const { vendorId } = requireVendor(request);
  const snap = await db.collection("serviceRequests").where("vendorId", "==", vendorId).orderBy("createdAt", "desc").limit(300).get();
  const jobs = snap.docs
    .map((d) => serializeServiceRequest(d, { forStaff: true }))
    .sort((a, b) => (b.createdAt ?? 0) - (a.createdAt ?? 0));
  return { jobs };
});

/// Vendor schedules or completes one of its assigned jobs.
export const updateServiceJob = onCall<{ id: string; status: string; scheduledFor?: number | null }>(
  { region: "us-central1" },
  async (request) => {
    const { vendorId } = requireVendor(request);
    const id = cleanDocId(request.data?.id, "id");
    const status = cleanEnum(request.data?.status, ["scheduled", "completed"] as const, "status");
    const ref = db.collection("serviceRequests").doc(id);
    const snap = await ref.get();
    if (!snap.exists || snap.data()?.vendorId !== vendorId) throw new HttpsError("not-found", "Job not found.");
    if (["completed", "cancelled"].includes(snap.data()?.status)) {
      throw new HttpsError("failed-precondition", "This job is already closed.");
    }
    const update: Record<string, unknown> = { status, updatedAt: FieldValue.serverTimestamp() };
    const s = request.data?.scheduledFor;
    if (s !== undefined && s !== null) {
      if (typeof s !== "number" || !Number.isFinite(s)) throw new HttpsError("invalid-argument", "scheduledFor is invalid.");
      update.scheduledFor = Timestamp.fromMillis(s);
    }
    await ref.update(update);
    return { ok: true };
  },
);
