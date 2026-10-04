"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.approveVendorApplication = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const require_role_1 = require("../shared/auth/require_role");
const send_mail_1 = require("../shared/mail/send_mail");
const vendor_application_emails_1 = require("../shared/mail/vendor_application_emails");
/// Admin-only. Turns a pending vendorApplications/{id} doc into a real
/// vendors/{vendorId} doc, and grants the applicant's account the
/// 'vendor' role + vendorId custom claim so they can call vendor-scoped
/// functions (create/update their own products) immediately after their
/// next token refresh.
exports.approveVendorApplication = (0, https_1.onCall)({ region: "us-central1", secrets: [send_mail_1.smtpUser, send_mail_1.smtpPass] }, async (request) => {
    (0, require_role_1.requireRole)(request, ["super_admin"]);
    const { applicationId } = request.data;
    if (!applicationId) {
        throw new https_1.HttpsError("invalid-argument", "applicationId is required.");
    }
    const appRef = firebase_1.db.collection("vendorApplications").doc(applicationId);
    const appSnap = await appRef.get();
    if (!appSnap.exists) {
        throw new https_1.HttpsError("not-found", "Application not found.");
    }
    const application = appSnap.data();
    if (application.status !== "pending") {
        throw new https_1.HttpsError("failed-precondition", `Application is already '${application.status}'.`);
    }
    const vendorRef = firebase_1.db.collection("vendors").doc();
    await firebase_1.db.runTransaction(async (tx) => {
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
            createdAt: firestore_1.FieldValue.serverTimestamp(),
        });
        tx.update(appRef, {
            status: "approved",
            vendorId: vendorRef.id,
            reviewedAt: firestore_1.FieldValue.serverTimestamp(),
            reviewedBy: request.auth.uid,
        });
    });
    // Merge, not overwrite — preserves any other claims (e.g. if this
    // account is ever also a customer in other data).
    const user = await firebase_1.auth.getUser(application.uid);
    await firebase_1.auth.setCustomUserClaims(application.uid, {
        ...user.customClaims,
        role: "vendor",
        vendorId: vendorRef.id,
    });
    if (application.email) {
        await (0, vendor_application_emails_1.sendVendorApprovedEmail)(application.email, application.businessName);
    }
    return { vendorId: vendorRef.id };
});
