"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.vendorPasswordSignIn = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const password_1 = require("../shared/auth/password");
/// Email + password sign-in for already-approved vendors (set via the
/// /set-password link in the approval email — see set_vendor_password.ts).
/// Looked up by email rather than username: vendors never go through
/// signUp, so they have no entry in the `usernames` collection — email is
/// denormalized onto users/{uid} by approveVendorApplication specifically
/// so this lookup works. Phone + WhatsApp OTP (auth-verifyPhoneOtp) stays
/// available as the fallback/recovery path, same account either way.
exports.vendorPasswordSignIn = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    const email = request.data?.email?.trim().toLowerCase();
    const password = request.data?.password ?? "";
    if (!email || !password) {
        throw new https_1.HttpsError("invalid-argument", "email and password are required.");
    }
    const usersSnap = await firebase_1.db.collection("users").where("email", "==", email).limit(1).get();
    if (usersSnap.empty) {
        // Same message as a wrong password — don't reveal whether the email exists.
        throw new https_1.HttpsError("permission-denied", "Incorrect email or password.");
    }
    const userDoc = usersSnap.docs[0];
    const user = userDoc.data();
    const passwordHash = user.passwordHash;
    if (!passwordHash) {
        throw new https_1.HttpsError("permission-denied", "Incorrect email or password.");
    }
    const passwordOk = await (0, password_1.verifyPassword)(password, passwordHash);
    if (!passwordOk) {
        throw new https_1.HttpsError("permission-denied", "Incorrect email or password.");
    }
    const userRecord = await firebase_1.auth.getUser(userDoc.id);
    if (userRecord.customClaims?.role !== "vendor") {
        throw new https_1.HttpsError("permission-denied", "This account is not an approved vendor.");
    }
    await userDoc.ref.update({ lastSignInAt: firestore_1.FieldValue.serverTimestamp() });
    const customToken = await firebase_1.auth.createCustomToken(userDoc.id);
    return { customToken };
});
