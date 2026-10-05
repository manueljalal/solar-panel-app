import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
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
    if (application.status !== "pending") {
      throw new HttpsError("failed-precondition", `Application is already '${application.status}'.`);
    }

    const vendorRef = db.collection("vendors").doc();

    await db.runTransaction(async (tx) => {
      tx.set(vendorRef, {
        ownerUid: application.uid,
        businessName: application.businessName,
        city: application.city,
        address: application.address ?? null,
        phone: application.phone,
        location: application.location ?? null,
        status: "approved",
        rating: 0,
        reviewCount: 0,
        logoUrl: "",
        createdAt: FieldValue.serverTimestamp(),
      });
      tx.update(appRef, {
        status: "approved",
        vendorId: vendorRef.id,
        reviewedAt: FieldValue.serverTimestamp(),
        reviewedBy: request.auth!.uid,
      });
    });

    // Merge, not overwrite — preserves any other claims (e.g. if this
    // account is ever also a customer in other data).
    const user = await auth.getUser(application.uid);
    await auth.setCustomUserClaims(application.uid, {
      ...user.customClaims,
      role: "vendor",
      vendorId: vendorRef.id,
    });

    // Denormalized onto users/{uid} so vendorPasswordSignIn can look the
    // account up by email once a password is set — vendorApplications
    // itself isn't client-readable (see firestore.rules) and isn't keyed
    // by email anyway.
    if (application.email) {
      await db.collection("users").doc(application.uid).set({ email: application.email }, { merge: true });
    }

    if (application.email) {
      const passwordSetupToken = await createPasswordSetupToken(application.uid);
      await sendVendorApprovedEmail(application.email, application.businessName, passwordSetupToken);
    }

    return { vendorId: vendorRef.id };
  },
);
