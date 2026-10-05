"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.vendorPasswordSignIn = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const password_1 = require("../shared/auth/password");
/// Email + password sign-in for approved vendors who've set a password
/// via setVendorPassword. Vendors can also always sign in with phone +
/// OTP (verifyPhoneOtp) — this is an additional path, not a replacement;
/// unlike the customer signIn() flow, there's no device step-up here,
/// since the vendor's phone number is already a standing second channel
/// for recovering account access if a password is ever compromised.
exports.vendorPasswordSignIn = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    const email = request.data?.email?.trim().toLowerCase();
    const password = request.data?.password ?? "";
    if (!email || !password) {
        throw new https_1.HttpsError("invalid-argument", "email and password are required.");
    }
    const usersSnap = await firebase_1.db.collection("users").where("email", "==", email).limit(1).get();
    if (usersSnap.empty) {
        // Same message as a wrong password — don't reveal whether the
        // email exists.
        throw new https_1.HttpsError("permission-denied", "Incorrect email or password.");
    }
    const userDoc = usersSnap.docs[0];
    const user = userDoc.data();
    if (!user.passwordHash) {
        throw new https_1.HttpsError("permission-denied", "Incorrect email or password.");
    }
    const passwordOk = await (0, password_1.verifyPassword)(password, user.passwordHash);
    if (!passwordOk) {
        throw new https_1.HttpsError("permission-denied", "Incorrect email or password.");
    }
    await userDoc.ref.update({ lastSignInAt: firestore_1.FieldValue.serverTimestamp() });
    const customToken = await firebase_1.auth.createCustomToken(userDoc.id);
    return { customToken };
});
