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
exports.consumePhoneOtp = consumePhoneOtp;
const https_1 = require("firebase-functions/v2/https");
const crypto = __importStar(require("crypto"));
const firebase_1 = require("../firebase");
const MAX_ATTEMPTS = 5; // lock the code after this many wrong guesses
function hashOtp(otp, phone) {
    // Salted with the phone number so two users who happen to get the same
    // 6-digit code don't produce identical hashes in the datastore.
    return crypto.createHash("sha256").update(`${phone}:${otp}`).digest("hex");
}
/// Checks a code against the pending phoneOtps/{phone} doc (written by
/// requestPhoneOtp) and consumes it on success — shared by every flow
/// that needs "prove you control this phone number right now"
/// (verifyPhoneOtp's own sign-in, signUp, and signInWithOtpStepUp).
/// Throws HttpsError on any failure (not found / expired / too many
/// attempts / wrong code); callers don't need their own error handling.
async function consumePhoneOtp(phone, otp) {
    const otpRef = firebase_1.db.collection("phoneOtps").doc(phone);
    await firebase_1.db.runTransaction(async (tx) => {
        const snap = await tx.get(otpRef);
        if (!snap.exists) {
            throw new https_1.HttpsError("not-found", "No code was requested for this number.");
        }
        const data = snap.data();
        const expiresAt = data.expiresAt?.toMillis?.() ?? 0;
        if (Date.now() > expiresAt) {
            tx.delete(otpRef);
            throw new https_1.HttpsError("deadline-exceeded", "That code has expired. Request a new one.");
        }
        const attempts = (data.attempts ?? 0);
        if (attempts >= MAX_ATTEMPTS) {
            tx.delete(otpRef);
            throw new https_1.HttpsError("resource-exhausted", "Too many incorrect attempts. Request a new code.");
        }
        const expectedHash = Buffer.from(data.hash, "hex");
        const actualHash = Buffer.from(hashOtp(otp, phone), "hex");
        // Constant-time compare (crypto.timingSafeEqual), not `===` — this is
        // exactly the kind of secret-comparison where a timing side-channel
        // is a real (if narrow) risk.
        const matches = expectedHash.length === actualHash.length && crypto.timingSafeEqual(expectedHash, actualHash);
        if (!matches) {
            tx.update(otpRef, { attempts: attempts + 1 });
            throw new https_1.HttpsError("permission-denied", "Incorrect code.");
        }
        tx.delete(otpRef);
    });
}
