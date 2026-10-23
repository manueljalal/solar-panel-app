import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { requireRole } from "../shared/auth/require_role";
import { smtpUser, smtpPass } from "../shared/mail/send_mail";
import { sendVendorRejectedEmail } from "../shared/mail/vendor_application_emails";
import { cleanDocId, cleanText } from "../shared/validation/sanitize";

interface RejectInput {
  applicationId: string;
  reason?: string;
}

export const rejectVendorApplication = onCall<RejectInput>(
  { region: "us-central1", secrets: [smtpUser, smtpPass] },
  async (request) => {
    requireRole(request, ["super_admin"]);

    const { applicationId, reason } = request.data;
    if (!applicationId) {
      throw new HttpsError("invalid-argument", "applicationId is required.");
    }

    const appRef = db.collection("vendorApplications").doc(cleanDocId(applicationId, "applicationId"));
    const cleanReason = cleanText(reason, "reason", { max: 500, multiline: true }) || null;

    // Read + write in one transaction so a reject can't land on an
    // application another admin is approving at the same moment.
    const application = await db.runTransaction(async (tx) => {
      const appSnap = await tx.get(appRef);
      const application = appSnap.data();
      if (!appSnap.exists || !application) {
        throw new HttpsError("not-found", "Application not found.");
      }
      if (application.status !== "pending") {
        throw new HttpsError("failed-precondition", `Application is already '${application.status}'.`);
      }
      tx.update(appRef, {
        status: "rejected",
        rejectionReason: cleanReason,
        reviewedAt: FieldValue.serverTimestamp(),
        reviewedBy: request.auth!.uid,
      });
      return application;
    });

    if (application.email) {
      await sendVendorRejectedEmail(application.email, application.businessName, cleanReason ?? undefined);
    }

    return { ok: true };
  },
);
