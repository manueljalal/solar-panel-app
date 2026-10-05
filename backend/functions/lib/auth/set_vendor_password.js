"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.setVendorPassword = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const password_1 = require("../shared/auth/password");
const password_setup_token_1 = require("../shared/auth/password_setup_token");
/// Consumes a one-time setup token (minted by approveVendorApplication and
/// delivered via the approval email) to set a password on the vendor's
/// users/{uid} doc. No Firebase Auth session is required — the token
/// itself, proven by its hash matching a stored, unexpired, unused
/// record, is the only credential needed here, the same trust model
/// signUp() uses for its own bcrypt-hashed passwordHash field.
exports.setVendorPassword = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    const token = request.data?.token?.trim();
    const password = request.data?.password ?? "";
    if (!token) {
        throw new https_1.HttpsError("invalid-argument", "token is required.");
    }
    if (!(0, password_1.isValidPassword)(password)) {
        throw new https_1.HttpsError("invalid-argument", "password must be at least 8 characters and include an uppercase letter, a lowercase letter, a number, and a symbol.");
    }
    const consumed = await (0, password_setup_token_1.consumePasswordSetupToken)(token);
    if (!consumed) {
        throw new https_1.HttpsError("failed-precondition", "This link is invalid or has expired.");
    }
    const passwordHash = await (0, password_1.hashPassword)(password);
    await firebase_1.db.collection("users").doc(consumed.vendorUid).set({
        passwordHash,
        passwordSetAt: firestore_1.FieldValue.serverTimestamp(),
    }, { merge: true });
    return { ok: true };
});
