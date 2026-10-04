"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.signInOtpStepUp = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const verify_otp_1 = require("../shared/auth/verify_otp");
const password_1 = require("../shared/auth/password");
/// Completes the step-up signIn demands when it sees an unrecognized
/// deviceId: the client already called requestPhoneOtp (against the
/// phone number on this user's profile) before calling this. On a
/// correct code, this device is added to knownDeviceIds permanently —
/// future signIns from it won't need OTP again — and a token is issued.
exports.signInOtpStepUp = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    const username = (0, password_1.normalizeUsername)(request.data?.username ?? "");
    const otp = request.data?.otp?.trim();
    const deviceId = request.data?.deviceId?.trim();
    if (!username || !otp || !deviceId) {
        throw new https_1.HttpsError("invalid-argument", "username, otp, and deviceId are required.");
    }
    const usernameSnap = await firebase_1.db.collection("usernames").doc(username).get();
    if (!usernameSnap.exists) {
        throw new https_1.HttpsError("not-found", "Account not found.");
    }
    const uid = usernameSnap.data().uid;
    const userRef = firebase_1.db.collection("users").doc(uid);
    const userSnap = await userRef.get();
    if (!userSnap.exists) {
        throw new https_1.HttpsError("not-found", "Account not found.");
    }
    const phone = userSnap.data().phone;
    await (0, verify_otp_1.consumePhoneOtp)(phone, otp);
    await userRef.update({
        knownDeviceIds: firestore_1.FieldValue.arrayUnion(deviceId),
        lastSignInAt: firestore_1.FieldValue.serverTimestamp(),
    });
    const customToken = await firebase_1.auth.createCustomToken(uid);
    return { customToken };
});
