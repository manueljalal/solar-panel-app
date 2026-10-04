"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.signUp = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const crypto_1 = require("crypto");
const firebase_1 = require("../shared/firebase");
const verify_otp_1 = require("../shared/auth/verify_otp");
const password_1 = require("../shared/auth/password");
const E164_PATTERN = /^\+[1-9]\d{6,14}$/;
/// Real registration: name + username + password + phone, with the phone
/// number proven via a WhatsApp-delivered OTP (requestPhoneOtp must have
/// been called first) in the SAME request as setting the password — so a
/// username+password account can't be created without ever proving phone
/// ownership. Password is hashed with bcrypt and stored on the user's own
/// users/{uid} doc; Firebase Auth itself has no password set for this
/// user (we mint custom tokens instead, the same mechanism the phone-only
/// flow already uses), since the credential check is entirely our own.
exports.signUp = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    const name = request.data?.name?.trim();
    const username = (0, password_1.normalizeUsername)(request.data?.username ?? "");
    const password = request.data?.password ?? "";
    const phone = request.data?.phone?.trim();
    const otp = request.data?.otp?.trim();
    const location = request.data?.location ?? null;
    const deviceId = request.data?.deviceId?.trim() || null;
    if (!name)
        throw new https_1.HttpsError("invalid-argument", "name is required.");
    if (!(0, password_1.isValidUsername)(username)) {
        throw new https_1.HttpsError("invalid-argument", "username must be 3-20 characters: lowercase letters, numbers, underscores only.");
    }
    if (!(0, password_1.isValidPassword)(password)) {
        throw new https_1.HttpsError("invalid-argument", "password must be at least 8 characters and include an uppercase letter, a lowercase letter, a number, and a symbol.");
    }
    if (!phone || !E164_PATTERN.test(phone)) {
        throw new https_1.HttpsError("invalid-argument", "phone must be in E.164 format, e.g. +9647501234567.");
    }
    if (!otp)
        throw new https_1.HttpsError("invalid-argument", "otp is required.");
    // Prove phone ownership BEFORE reserving the username / creating
    // anything — a failed OTP check should leave no trace.
    await (0, verify_otp_1.consumePhoneOtp)(phone, otp);
    const usernameRef = firebase_1.db.collection("usernames").doc(username);
    const uid = (0, crypto_1.randomUUID)();
    // Username reservation happens before createUser/createCustomToken so
    // "That username is taken" still fails cleanly with nothing else
    // created — but everything AFTER this point must succeed-or-rollback
    // together. createCustomToken in particular depends on IAM
    // (roles/iam.serviceAccountTokenCreator on the function's own service
    // account) and can fail independently of everything else; a prior
    // version of this function called it LAST, after createUser + the
    // Firestore profile write, so an IAM failure there left a real,
    // permanent account behind with no token ever returned — the client
    // saw a hard failure while the account had actually been created,
    // and a retry then failed with "username taken" against an account
    // the user never knew existed. Minting the token FIRST (right after
    // reserving the username, before any other persistent write) means a
    // late failure here can't leave an orphaned account: if this throws,
    // we roll back the username reservation ourselves before rethrowing.
    await firebase_1.db.runTransaction(async (tx) => {
        const usernameSnap = await tx.get(usernameRef);
        if (usernameSnap.exists) {
            throw new https_1.HttpsError("already-exists", "That username is taken.");
        }
        tx.set(usernameRef, { uid, createdAt: firestore_1.FieldValue.serverTimestamp() });
    });
    let customToken;
    try {
        customToken = await firebase_1.auth.createCustomToken(uid);
    }
    catch (e) {
        await usernameRef.delete();
        throw e;
    }
    const passwordHash = await (0, password_1.hashPassword)(password);
    try {
        await firebase_1.auth.createUser({ uid, displayName: name, phoneNumber: phone });
        await firebase_1.db
            .collection("users")
            .doc(uid)
            .set({
            name,
            username,
            passwordHash,
            phone,
            location,
            role: "customer",
            knownDeviceIds: deviceId ? [deviceId] : [],
            createdAt: firestore_1.FieldValue.serverTimestamp(),
            lastSignInAt: firestore_1.FieldValue.serverTimestamp(),
        });
    }
    catch (e) {
        await usernameRef.delete();
        if (e.code === "auth/phone-number-already-exists") {
            throw new https_1.HttpsError("already-exists", "An account with that phone number already exists.");
        }
        throw e;
    }
    return { customToken };
});
