"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.rejectVendorApplication = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const require_role_1 = require("../shared/auth/require_role");
const send_mail_1 = require("../shared/mail/send_mail");
const vendor_application_emails_1 = require("../shared/mail/vendor_application_emails");
exports.rejectVendorApplication = (0, https_1.onCall)({ region: "us-central1", secrets: [send_mail_1.smtpUser, send_mail_1.smtpPass] }, async (request) => {
    (0, require_role_1.requireRole)(request, ["super_admin"]);
    const { applicationId, reason } = request.data;
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
    await appRef.update({
        status: "rejected",
        rejectionReason: reason ?? null,
        reviewedAt: firestore_1.FieldValue.serverTimestamp(),
        reviewedBy: request.auth.uid,
    });
    if (application.email) {
        await (0, vendor_application_emails_1.sendVendorRejectedEmail)(application.email, application.businessName, reason);
    }
    return { ok: true };
});
