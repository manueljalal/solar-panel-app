"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.createPasswordSetupToken = createPasswordSetupToken;
exports.consumePasswordSetupToken = consumePasswordSetupToken;
const crypto = __importStar(require("crypto"));
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../firebase");
const TOKEN_BYTES = 32; // 256 bits — not brute-forceable, unlike a 6-digit OTP
const TOKEN_TTL_MS = 24 * 60 * 60 * 1000; // 24h, generous since this is a one-time onboarding action
function hashToken(token) {
    return crypto.createHash("sha256").update(token).digest("hex");
}
/// Creates a one-time password-setup token for a just-approved vendor.
/// The raw token is only ever returned here (to embed in the approval
/// email's link) — what's persisted is its hash, so a Firestore read
/// alone can't be used to set someone else's password.
async function createPasswordSetupToken(vendorUid) {
    const token = crypto.randomBytes(TOKEN_BYTES).toString("base64url");
    await firebase_1.db
        .collection("vendorPasswordSetupTokens")
        .doc(hashToken(token))
        .set({
        vendorUid,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        expiresAt: new Date(Date.now() + TOKEN_TTL_MS),
        usedAt: null,
    });
    return token;
}
/// Validates and immediately invalidates a setup token (single use).
/// Returns the vendor uid it was issued for, or null if the token is
/// missing, expired, or already used — callers return a generic "invalid
/// or expired link" rather than distinguishing these, so a guessed token
/// id can't be used to probe which case applies.
async function consumePasswordSetupToken(token) {
    const tokenRef = firebase_1.db.collection("vendorPasswordSetupTokens").doc(hashToken(token));
    return firebase_1.db.runTransaction(async (tx) => {
        const snap = await tx.get(tokenRef);
        if (!snap.exists)
            return null;
        const data = snap.data();
        if (data.usedAt)
            return null;
        const expiresAt = data.expiresAt?.toMillis?.() ?? 0;
        if (Date.now() > expiresAt)
            return null;
        tx.update(tokenRef, { usedAt: firestore_1.FieldValue.serverTimestamp() });
        return { vendorUid: data.vendorUid };
    });
}
