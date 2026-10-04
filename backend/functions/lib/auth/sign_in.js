"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.signIn = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const password_1 = require("../shared/auth/password");
/// Real sign-in: username + password, checked against the bcrypt hash on
/// users/{uid} (see sign_up.ts — there is no Firebase Auth password for
/// this user, the check is entirely ours). If the calling device isn't
/// in that user's knownDeviceIds, this refuses with a distinct error
/// code (`step-up-required`) instead of a token — the client is expected
/// to fall back to requestPhoneOtp + signInWithOtpStepUp to prove the
/// device before getting in. A device IS trusted (and skips OTP) once
/// it's been through that step-up once, or was present at signup.
exports.signIn = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    const username = (0, password_1.normalizeUsername)(request.data?.username ?? "");
    const password = request.data?.password ?? "";
    const deviceId = request.data?.deviceId?.trim() || null;
    if (!username || !password) {
        throw new https_1.HttpsError("invalid-argument", "username and password are required.");
    }
    const usernameSnap = await firebase_1.db.collection("usernames").doc(username).get();
    if (!usernameSnap.exists) {
        // Same message as a wrong password — don't reveal whether the
        // username exists.
        throw new https_1.HttpsError("permission-denied", "Incorrect username or password.");
    }
    const uid = usernameSnap.data().uid;
    const userRef = firebase_1.db.collection("users").doc(uid);
    const userSnap = await userRef.get();
    if (!userSnap.exists) {
        throw new https_1.HttpsError("permission-denied", "Incorrect username or password.");
    }
    const user = userSnap.data();
    const passwordOk = await (0, password_1.verifyPassword)(password, user.passwordHash);
    if (!passwordOk) {
        throw new https_1.HttpsError("permission-denied", "Incorrect username or password.");
    }
    const knownDeviceIds = (user.knownDeviceIds ?? []);
    if (deviceId && !knownDeviceIds.includes(deviceId)) {
        // Correct credentials, unrecognized device — require a fresh phone
        // OTP (via requestPhoneOtp + signInWithOtpStepUp) before minting a
        // token. No token is issued here.
        //
        // The phone number is encoded directly in the message string
        // ("step-up-required:+9647...") rather than passed via HttpsError's
        // `details` param — `details` does NOT reliably reach the Flutter
        // client over the callable HTTP transport (confirmed: a client
        // calling this function got only {message, status} back, details
        // was silently dropped), so relying on it left the client unable to
        // ever start the step-up flow — every step-up case fell through to
        // a generic "couldn't sign in" error instead. message is proven to
        // arrive intact, so that's what carries the data now.
        throw new https_1.HttpsError("failed-precondition", `step-up-required:${user.phone}`);
    }
    await userRef.update({ lastSignInAt: firestore_1.FieldValue.serverTimestamp() });
    const customToken = await firebase_1.auth.createCustomToken(uid);
    return { customToken };
});
