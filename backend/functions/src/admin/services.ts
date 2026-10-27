import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { requireRole } from "../shared/auth/require_role";
import { cleanDocId, cleanEnum, cleanText } from "../shared/validation/sanitize";
import { SERVICE_STATUSES, serializeServiceRequest } from "../shared/services";

/// All service requests, newest first.
export const listServiceRequests = onCall({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);
  const snap = await db.collection("serviceRequests").orderBy("createdAt", "desc").limit(500).get();
  return { requests: snap.docs.map((d) => serializeServiceRequest(d, { forStaff: true })) };
});

interface UpdateInput {
  id: string;
  status?: string;
  /** Assign to an approved vendor; "" to unassign. */
  vendorId?: string;
  scheduledFor?: number | null;
  adminNote?: string;
}

/// Admin schedules, assigns, completes or cancels a service request.
export const updateServiceRequest = onCall<UpdateInput>({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);
  const id = cleanDocId(request.data?.id, "id");
  const ref = db.collection("serviceRequests").doc(id);
  if (!(await ref.get()).exists) throw new HttpsError("not-found", "Request not found.");

  const update: Record<string, unknown> = { updatedAt: FieldValue.serverTimestamp() };
  if (request.data?.status !== undefined) update.status = cleanEnum(request.data.status, SERVICE_STATUSES, "status");
  if (request.data?.adminNote !== undefined) {
    update.adminNote = cleanText(request.data.adminNote, "adminNote", { max: 1000, multiline: true });
  }
  if (request.data?.scheduledFor !== undefined) {
    const s = request.data.scheduledFor;
    if (s !== null && (typeof s !== "number" || !Number.isFinite(s))) {
      throw new HttpsError("invalid-argument", "scheduledFor is invalid.");
    }
    update.scheduledFor = s === null ? null : Timestamp.fromMillis(s);
  }
  if (request.data?.vendorId !== undefined) {
    if (request.data.vendorId === "") {
      update.vendorId = null;
      update.vendorName = null;
    } else {
      const vendorId = cleanDocId(request.data.vendorId, "vendorId");
      const vendor = (await db.collection("vendors").doc(vendorId).get()).data();
      if (!vendor || vendor.status !== "approved") throw new HttpsError("invalid-argument", "Choose an approved vendor.");
      update.vendorId = vendorId;
      update.vendorName = vendor.businessName ?? "";
    }
  }
  await ref.update(update);
  return { ok: true };
});

/// Call-center details shown in the app (config/support is public-read).
export const updateSupportConfig = onCall<{ phone: string; whatsapp?: string; hours?: string; email?: string }>(
  { region: "us-central1" },
  async (request) => {
    requireRole(request, ["super_admin"]);
    const phone = cleanText(request.data?.phone, "phone", { max: 20, min: 1 });
    const whatsapp = cleanText(request.data?.whatsapp, "whatsapp", { max: 20 });
    const E164 = /^\+[1-9]\d{6,14}$/;
    if (!E164.test(phone)) throw new HttpsError("invalid-argument", "Phone must look like +9647501234567.");
    if (whatsapp && !E164.test(whatsapp)) throw new HttpsError("invalid-argument", "WhatsApp must look like +9647501234567.");
    await db.collection("config").doc("support").set({
      phone,
      whatsapp: whatsapp || phone,
      hours: cleanText(request.data?.hours, "hours", { max: 120 }),
      email: cleanText(request.data?.email, "email", { max: 254 }),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return { ok: true };
  },
);
