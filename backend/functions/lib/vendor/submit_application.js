"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.submitApplication = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const MAX_STRING_LENGTH = 500;
const MAX_EMAIL_LENGTH = 254;
const E164_PATTERN = /^\+[1-9]\d{6,14}$/;
// Intentionally simple — RFC 5322 is not worth replicating here; this
// catches typos and obviously-malformed input, the email itself is
// confirmed to work once the approval email actually lands.
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
/// Any signed-in user may apply to become a vendor (see Account tab's
/// "Own a solar business? Apply" and the web vendor portal's /apply
/// page). Writes the vendorApplications doc server-side instead of the
/// client writing it directly — uid comes from the verified auth token,
/// never a client-supplied field.
exports.submitApplication = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Sign in required.");
    }
    const uid = request.auth.uid;
    const businessName = request.data?.businessName?.trim();
    const city = request.data?.city?.trim();
    const address = request.data?.address?.trim() ?? "";
    const phone = request.data?.phone?.trim();
    const email = request.data?.email?.trim().toLowerCase();
    const note = request.data?.note?.trim() ?? "";
    const location = request.data?.location ?? null;
    if (!businessName || !city || !phone || !email) {
        throw new https_1.HttpsError("invalid-argument", "businessName, city, phone, and email are required.");
    }
    if (!E164_PATTERN.test(phone)) {
        throw new https_1.HttpsError("invalid-argument", "phone must be in E.164 format, e.g. +9647501234567.");
    }
    if (!EMAIL_PATTERN.test(email) || email.length > MAX_EMAIL_LENGTH) {
        throw new https_1.HttpsError("invalid-argument", "Enter a valid email address.");
    }
    for (const [key, value] of [
        ["businessName", businessName],
        ["city", city],
        ["address", address],
        ["note", note],
    ]) {
        if (value.length > MAX_STRING_LENGTH) {
            throw new https_1.HttpsError("invalid-argument", `${key} exceeds ${MAX_STRING_LENGTH} characters.`);
        }
    }
    const applicationRef = firebase_1.db.collection("vendorApplications").doc();
    await applicationRef.set({
        uid,
        businessName,
        city,
        address,
        phone,
        email,
        note,
        location,
        status: "pending",
        createdAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return { applicationId: applicationRef.id };
});
