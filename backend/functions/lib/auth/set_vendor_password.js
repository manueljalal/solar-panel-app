"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.setVendorPassword = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../shared/firebase");
const password_setup_token_1 = require("../shared/auth/password_setup_token");
const password_1 = require("../shared/auth/password");
/// Finalizes the one-time setup link sent by approveVendorApplication:
/// consumes the token (single use, 24h TTL — see password_setup_token.ts),
/// hashes the chosen password, and stores it on users/{uid} so
/// vendorPasswordSignIn can check it afterwards. Mirrors signUp's password
/// handling: Firebase Auth itself never gets a password, the hash on
/// users/{uid} is the only credential store.
exports.setVendorPassword = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    const token = request.data?.token?.trim();
    const password = request.data?.password ?? "";
    if (!(0, password_1.isValidPassword)(password)) {
        throw new https_1.HttpsError("invalid-argument", "password must be at least 8 characters and include an uppercase letter, a lowercase letter, a number, and a symbol.");
    }
    const { uid } = await (0, password_setup_token_1.consumePasswordSetupToken)(token ?? "");
    const userRecord = await firebase_1.auth.getUser(uid);
    if (userRecord.customClaims?.role !== "vendor") {
        throw new https_1.HttpsError("failed-precondition", "This account is not an approved vendor.");
    }
    const passwordHash = await (0, password_1.hashPassword)(password);
    await firebase_1.db
        .collection("users")
        .doc(uid)
        .set({ passwordHash, passwordSetAt: firestore_1.FieldValue.serverTimestamp() }, { merge: true });
    const customToken = await firebase_1.auth.createCustomToken(uid);
    return { customToken };
});
