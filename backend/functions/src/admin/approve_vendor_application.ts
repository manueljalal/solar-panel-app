import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { db, auth } from "../shared/firebase";
import { requireRole } from "../shared/auth/require_role";
import { smtpUser, smtpPass } from "../shared/mail/send_mail";
import { sendVendorApprovedEmail } from "../shared/mail/vendor_application_emails";
import { createPasswordSetupToken } from "../shared/auth/password_setup_token";

interface ApproveInput {
  applicationId: string;
}

/// Admin-only. Turns a pending vendorApplications/{id} doc into a real
/// vendors/{vendorId} doc, and grants the applicant's account the
/// 'vendor' role + vendorId custom claim so they can call vendor-scoped
/// functions (create/update their own products) immediately after their
/// next token refresh.
export const approveVendorApplication = onCall<ApproveInput>(
  { region: "us-central1", secrets: [smtpUser, smtpPass] },
  async (request) => {
    requireRole(request, ["super_admin"]);

    const { applicationId } = request.data;
    if (!applicationId) {
      throw new HttpsError("invalid-argument", "applicationId is required.");
    }

    const appRef = db.collection("vendorApplications").doc(applicationId);
    const appSnap = await appRef.get();
    if (!appSnap.exists) {
      throw new HttpsError("not-found", "Application not found.");
    }
    const application = appSnap.data()!;

    // The applicant's account must really exist — Auth user AND profile —
    // before a vendor company is created for it.
    const applicant = await auth.getUser(application.uid).catch(() => null);
    const profile = await db.collection("users").doc(application.uid).get();
    if (!applicant || !profile.exists) {
      throw new HttpsError("failed-precondition", "The applicant's account no longer exists, so it can't be approved.");
    }
    if (applicant.customClaims?.role === "vendor" && applicant.customClaims?.vendorId) {
      throw new HttpsError("failed-precondition", "This account is already an approved vendor.");
    }

    const vendorRef = db.collection("vendors").doc();

    // Status is re-checked inside the transaction so two admins approving
    // at the same moment can't create two vendor companies.
    await db.runTransaction(async (tx) => {
      const fresh = await tx.get(appRef);
      if (fresh.data()?.status !== "pending") {
        throw new HttpsError("failed-precondition", `Application is already '${fresh.data()?.status}'.`);
      }
      tx.set(vendorRef, {
        ownerUid: application.uid,
        businessName: application.businessName,
        city: application.city,
        address: application.address ?? null,
        phone: application.phone,
        country: application.country === "CN" ? "CN" : "IQ",
        location: application.location ?? null,
        status: "approved",
        rating: 0,
        reviewCount: 0,
        logoUrl: application.logoUrl ?? "",
        createdAt: FieldValue.serverTimestamp(),
      });
      tx.update(appRef, {
        status: "approved",
        vendorId: vendorRef.id,
        reviewedAt: FieldValue.serverTimestamp(),
        reviewedBy: request.auth!.uid,
      });
    });

    // The vendor only exists once the account also carries the vendor role.
    // If granting it fails, undo the company + approval so the application
    // is pending again and can simply be approved again.
    try {
      await auth.setCustomUserClaims(application.uid, {
        ...applicant.customClaims,
        role: "vendor",
        vendorId: vendorRef.id,
      });
    } catch (e) {
      logger.error("approve: granting vendor role failed, rolling back", { applicationId, err: String(e) });
      const batch = db.batch();
      batch.delete(vendorRef);
      batch.update(appRef, {
        status: "pending",
        vendorId: FieldValue.delete(),
        reviewedAt: FieldValue.delete(),
        reviewedBy: FieldValue.delete(),
      });
      await batch.commit();
      throw new HttpsError("internal", "Couldn't grant the vendor role — nothing was changed, try again.");
    }

    // Approval is complete from here. The rest is notification: a failure
    // is logged (the admin can use "Resend setup link") but doesn't undo it.
    if (application.email) {
      try {
        // Lets the vendor sign in with this email (see resolveAccountUids).
        await db.collection("users").doc(application.uid).set({ email: application.email }, { merge: true });
        const passwordSetupToken = await createPasswordSetupToken(application.uid);
        await sendVendorApprovedEmail(application.email, application.businessName, passwordSetupToken);
      } catch (e) {
        logger.error("approve: setup email failed (approval stands)", { applicationId, err: String(e) });
      }
    }

    return { vendorId: vendorRef.id };
  },
);
