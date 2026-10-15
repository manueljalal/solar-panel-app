"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.resendPasswordSetup = void 0;
const https_1 = require("firebase-functions/v2/https");
const firebase_1 = require("../shared/firebase");
const require_role_1 = require("../shared/auth/require_role");
const send_mail_1 = require("../shared/mail/send_mail");
const vendor_application_emails_1 = require("../shared/mail/vendor_application_emails");
const password_setup_token_1 = require("../shared/auth/password_setup_token");
/// Admin-only. Sends an already-approved vendor a fresh "set your
/// password" link (the original is single-use and expires in 24h). Each
/// call mints a new token and emails it to the application's address.
exports.resendPasswordSetup = (0, https_1.onCall)({ region: "us-central1", secrets: [send_mail_1.smtpUser, send_mail_1.smtpPass] }, async (request) => {
    (0, require_role_1.requireRole)(request, ["super_admin"]);
    const { applicationId } = request.data ?? {};
    if (!applicationId || typeof applicationId !== "string") {
        throw new https_1.HttpsError("invalid-argument", "applicationId is required.");
    }
    const snap = await firebase_1.db.collection("vendorApplications").doc(applicationId).get();
    const application = snap.data();
    if (!snap.exists || !application) {
        throw new https_1.HttpsError("not-found", "Application not found.");
    }
    if (application.status !== "approved") {
        throw new https_1.HttpsError("failed-precondition", "Only approved applications can be sent a setup link.");
    }
    if (!application.email) {
        throw new https_1.HttpsError("failed-precondition", "This application has no email address.");
    }
    await firebase_1.db.collection("users").doc(application.uid).set({ email: application.email }, { merge: true });
    const token = await (0, password_setup_token_1.createPasswordSetupToken)(application.uid);
    await (0, vendor_application_emails_1.sendVendorApprovedEmail)(application.email, application.businessName, token);
    return { ok: true };
});
