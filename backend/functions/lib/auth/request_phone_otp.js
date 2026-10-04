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
exports.requestPhoneOtp = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const crypto = __importStar(require("crypto"));
const firebase_1 = require("../shared/firebase");
const send_otp_1 = require("../shared/whatsapp/send_otp");
const OTP_TTL_MS = 5 * 60 * 1000; // 5 minutes
const RESEND_COOLDOWN_MS = 30 * 1000; // 30s between sends to the same number
const MAX_SENDS_PER_HOUR = 5; // basic abuse guard per phone number
const MAX_SENDS_PER_DEVICE_PER_HOUR = 8; // a device spraying many numbers is the attack this stops
function generateOtp() {
    // Cryptographically secure, not Math.random() — this gates account
    // access, so it needs to resist prediction, not just collision.
    const bytes = crypto.randomBytes(4);
    const num = bytes.readUInt32BE(0) % 1000000;
    return num.toString().padStart(6, "0");
}
function hashOtp(otp, phone) {
    // Salted with the phone number so two users who happen to get the same
    // 6-digit code don't produce identical hashes in the datastore.
    return crypto.createHash("sha256").update(`${phone}:${otp}`).digest("hex");
}
const E164_PATTERN = /^\+[1-9]\d{6,14}$/;
/// Starts phone verification: generates an OTP, stores only its salted
/// hash (never the plaintext code) in Firestore with an expiry, and sends
/// it via WhatsApp. Rate-limited per phone number to resist SMS/WhatsApp-
/// bombing abuse — both a cooldown between sends and a per-hour cap.
///
/// The rate-limit check-and-reserve happens in a transaction (so two
/// concurrent requests can't both slip past the cooldown), but the actual
/// WhatsApp send happens AFTER the transaction commits, not inside it —
/// Firestore retries a transaction on write contention, and retrying a
/// side effect like "send a message" would mean a contended request can
/// send the OTP twice for one click.
exports.requestPhoneOtp = (0, https_1.onCall)({ region: "us-central1", secrets: [send_otp_1.whatsappAccessToken] }, async (request) => {
    const phone = request.data?.phone?.trim();
    const deviceId = request.data?.deviceId?.trim() || null;
    if (!phone || !E164_PATTERN.test(phone)) {
        throw new https_1.HttpsError("invalid-argument", "phone must be in E.164 format, e.g. +9647501234567.");
    }
    const otpRef = firebase_1.db.collection("phoneOtps").doc(phone);
    const deviceRef = deviceId ? firebase_1.db.collection("otpDeviceSends").doc(deviceId) : null;
    const otp = generateOtp();
    await firebase_1.db.runTransaction(async (tx) => {
        const now = Date.now();
        // All reads before any write — Firestore transactions require
        // this strict ordering (an earlier version of this function
        // violated it by writing deviceRef before reading otpRef, which
        // threw "Firestore transactions require all reads to be executed
        // before all writes" on every single call).
        const deviceSnap = deviceRef ? await tx.get(deviceRef) : null;
        const otpSnap = await tx.get(otpRef);
        // Per-device check first — a device already over its hourly cap
        // shouldn't get to probe phone numbers at all.
        let deviceSendsInLastHour = [];
        if (deviceRef) {
            deviceSendsInLastHour = deviceSnap.exists
                ? (deviceSnap.data().recentSends ?? []).filter((t) => now - t < 60 * 60 * 1000)
                : [];
            if (deviceSendsInLastHour.length >= MAX_SENDS_PER_DEVICE_PER_HOUR) {
                throw new https_1.HttpsError("resource-exhausted", "Too many codes requested from this device. Try later.");
            }
        }
        let recentSends = [now];
        if (otpSnap.exists) {
            const data = otpSnap.data();
            const lastSentAt = data.lastSentAt?.toMillis?.() ?? 0;
            if (now - lastSentAt < RESEND_COOLDOWN_MS) {
                throw new https_1.HttpsError("resource-exhausted", "Wait a moment before requesting another code.");
            }
            const sendsInLastHour = (data.recentSends ?? []).filter((t) => now - t < 60 * 60 * 1000);
            if (sendsInLastHour.length >= MAX_SENDS_PER_HOUR) {
                throw new https_1.HttpsError("resource-exhausted", "Too many codes requested for this number. Try later.");
            }
            recentSends = [...sendsInLastHour, now];
        }
        if (deviceRef) {
            tx.set(deviceRef, { recentSends: [...deviceSendsInLastHour, now], lastSentAt: firestore_1.FieldValue.serverTimestamp() });
        }
        tx.set(otpRef, {
            hash: hashOtp(otp, phone),
            expiresAt: new Date(now + OTP_TTL_MS),
            lastSentAt: firestore_1.FieldValue.serverTimestamp(),
            recentSends,
            attempts: 0,
            deviceId,
        });
    });
    await (0, send_otp_1.sendWhatsAppOtp)(phone, otp);
    return { ok: true, expiresInSeconds: OTP_TTL_MS / 1000 };
});
