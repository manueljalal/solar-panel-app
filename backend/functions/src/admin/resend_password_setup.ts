import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db } from "../shared/firebase";
import { requireRole } from "../shared/auth/require_role";
import { smtpUser, smtpPass } from "../shared/mail/send_mail";
import { sendVendorApprovedEmail } from "../shared/mail/vendor_application_emails";
import { createPasswordSetupToken } from "../shared/auth/password_setup_token";

interface ResendInput {
  applicationId: string;
}

/// Admin-only. Sends an already-approved vendor a fresh "set your
/// password" link (the original is single-use and expires in 24h). Each
/// call mints a new token and emails it to the application's address.
export const resendPasswordSetup = onCall<ResendInput>(
  { region: "us-central1", secrets: [smtpUser, smtpPass] },
  async (request) => {
    requireRole(request, ["super_admin"]);

    const { applicationId } = request.data ?? {};
    if (!applicationId || typeof applicationId !== "string") {
      throw new HttpsError("invalid-argument", "applicationId is required.");
    }

    const snap = await db.collection("vendorApplications").doc(applicationId).get();
    const application = snap.data();
    if (!snap.exists || !application) {
      throw new HttpsError("not-found", "Application not found.");
    }
    if (application.status !== "approved") {
      throw new HttpsError("failed-precondition", "Only approved applications can be sent a setup link.");
    }
    if (!application.email) {
      throw new HttpsError("failed-precondition", "This application has no email address.");
    }

    await db.collection("users").doc(application.uid).set({ email: application.email }, { merge: true });
    const token = await createPasswordSetupToken(application.uid);
    await sendVendorApprovedEmail(application.email, application.businessName, token);
    return { ok: true };
  },
);
