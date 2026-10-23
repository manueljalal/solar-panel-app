"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.consumeRateLimit = consumeRateLimit;
const https_1 = require("firebase-functions/v2/https");
const firebase_1 = require("./firebase");
/// Fixed-window-free rate limit: keeps the timestamps of recent hits on
/// rateLimits/{bucket}:{key} and refuses once `max` fall inside `windowMs`.
/// Same pattern requestPhoneOtp uses for its per-number cap, generalized so
/// every write that a free (anonymous) account can trigger has a ceiling.
///
/// The key should be something the caller can't rotate cheaply — a uid for
/// signed-in actions, the typed identifier for sign-in attempts. A new
/// anonymous uid is still free to mint, so this bounds abuse per account
/// rather than stopping it outright; App Check is the complement for that.
async function consumeRateLimit(bucket, key, { max, windowMs, message }) {
    // Firestore ids can't contain "/" and are capped at 1500 bytes.
    const id = `${bucket}:${key}`.replace(/\//g, "_").slice(0, 400);
    const ref = firebase_1.db.collection("rateLimits").doc(id);
    await firebase_1.db.runTransaction(async (tx) => {
        const now = Date.now();
        const snap = await tx.get(ref);
        const recent = (snap.data()?.hits ?? []).filter((t) => now - t < windowMs);
        if (recent.length >= max) {
            throw new https_1.HttpsError("resource-exhausted", message);
        }
        // expiresAt lets a Firestore TTL policy on rateLimits clean these up.
        tx.set(ref, { hits: [...recent, now], expiresAt: new Date(now + windowMs) });
    });
}
