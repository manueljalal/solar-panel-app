import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { requireRole } from "../shared/auth/require_role";
import { smtpUser, smtpPass } from "../shared/mail/send_mail";
import { sendVendorRejectedEmail } from "../shared/mail/vendor_application_emails";

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

    const appRef = db.collection("vendorApplications").doc(applicationId);
    const appSnap = await appRef.get();
    if (!appSnap.exists) {
      throw new HttpsError("not-found", "Application not found.");
    }
    const application = appSnap.data()!;
    if (application.status !== "pending") {
      throw new HttpsError("failed-precondition", `Application is already '${application.status}'.`);
    }

    await appRef.update({
      status: "rejected",
      rejectionReason: reason ?? null,
      reviewedAt: FieldValue.serverTimestamp(),
      reviewedBy: request.auth!.uid,
    });

    if (application.email) {
      await sendVendorRejectedEmail(application.email, application.businessName, reason);
    }

    return { ok: true };
  },
);
