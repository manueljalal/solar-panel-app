"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.signIn = void 0;
const https_1 = require("firebase-functions/v2/https");
const firebase_functions_1 = require("firebase-functions");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const password_1 = require("../shared/auth/password");
const resolve_account_1 = require("../shared/auth/resolve_account");
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
    // Required, not optional: an omitted deviceId used to skip the step-up
    // check below entirely, turning "unknown device needs OTP" into
    // "just don't send a device id".
    if (!deviceId) {
        throw new https_1.HttpsError("invalid-argument", "deviceId is required.");
    }
    // `username` may also be the vendor's application email — see
    // resolveAccountUids. Several accounts can share one email (repeat
    // applications), so the password picks the right one.
    const uids = await (0, resolve_account_1.resolveAccountUids)(username);
    let uid = null;
    let userRef = firebase_1.db.collection("users").doc("_");
    let user = null;
    for (const candidate of uids) {
        const ref = firebase_1.db.collection("users").doc(candidate);
        const snap = await ref.get();
        const data = snap.data();
        if (!snap.exists || !data || typeof data.passwordHash !== "string")
            continue;
        if (await (0, password_1.verifyPassword)(password, data.passwordHash)) {
            uid = candidate;
            userRef = ref;
            user = data;
            break;
        }
    }
    if (!uid || !user) {
        // Reason goes to the server log only — the client always gets the same
        // generic message so sign-in can't be used to probe for accounts.
        firebase_functions_1.logger.warn("signIn rejected", {
            identifierKind: username.includes("@") ? "email" : "username",
            candidates: uids.length,
            reason: uids.length === 0 ? "no-matching-account" : "password-mismatch",
        });
        // Same message whether the account is unknown or the password is
        // wrong — don't reveal which.
        throw new https_1.HttpsError("permission-denied", "Incorrect username or password.");
    }
    const knownDeviceIds = (user.knownDeviceIds ?? []);
    if (!knownDeviceIds.includes(deviceId)) {
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
