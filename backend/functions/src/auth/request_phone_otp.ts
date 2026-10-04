import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import * as crypto from "crypto";
import { db } from "../shared/firebase";
import { sendWhatsAppOtp, whatsappAccessToken } from "../shared/whatsapp/send_otp";

interface RequestOtpInput {
  phone: string; // E.164, e.g. "+9647501234567"
  deviceId?: string; // client-generated, persisted locally — see device_id.dart
}

const OTP_TTL_MS = 5 * 60 * 1000; // 5 minutes
const RESEND_COOLDOWN_MS = 30 * 1000; // 30s between sends to the same number
const MAX_SENDS_PER_HOUR = 5; // basic abuse guard per phone number
const MAX_SENDS_PER_DEVICE_PER_HOUR = 8; // a device spraying many numbers is the attack this stops

function generateOtp(): string {
  // Cryptographically secure, not Math.random() — this gates account
  // access, so it needs to resist prediction, not just collision.
  const bytes = crypto.randomBytes(4);
  const num = bytes.readUInt32BE(0) % 1_000_000;
  return num.toString().padStart(6, "0");
}

function hashOtp(otp: string, phone: string): string {
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
export const requestPhoneOtp = onCall<RequestOtpInput>(
  { region: "us-central1", secrets: [whatsappAccessToken] },
  async (request) => {
    const phone = request.data?.phone?.trim();
    const deviceId = request.data?.deviceId?.trim() || null;
    if (!phone || !E164_PATTERN.test(phone)) {
      throw new HttpsError("invalid-argument", "phone must be in E.164 format, e.g. +9647501234567.");
    }

    const otpRef = db.collection("phoneOtps").doc(phone);
    const deviceRef = deviceId ? db.collection("otpDeviceSends").doc(deviceId) : null;
    const otp = generateOtp();

    await db.runTransaction(async (tx) => {
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
      let deviceSendsInLastHour: number[] = [];
      if (deviceRef) {
        deviceSendsInLastHour = deviceSnap!.exists
          ? (deviceSnap!.data()!.recentSends ?? []).filter((t: number) => now - t < 60 * 60 * 1000)
          : [];
        if (deviceSendsInLastHour.length >= MAX_SENDS_PER_DEVICE_PER_HOUR) {
          throw new HttpsError("resource-exhausted", "Too many codes requested from this device. Try later.");
        }
      }

      let recentSends: number[] = [now];
      if (otpSnap.exists) {
        const data = otpSnap.data()!;
        const lastSentAt = data.lastSentAt?.toMillis?.() ?? 0;
        if (now - lastSentAt < RESEND_COOLDOWN_MS) {
          throw new HttpsError("resource-exhausted", "Wait a moment before requesting another code.");
        }

        const sendsInLastHour: number[] = (data.recentSends ?? []).filter((t: number) => now - t < 60 * 60 * 1000);
        if (sendsInLastHour.length >= MAX_SENDS_PER_HOUR) {
          throw new HttpsError("resource-exhausted", "Too many codes requested for this number. Try later.");
        }
        recentSends = [...sendsInLastHour, now];
      }

      if (deviceRef) {
        tx.set(deviceRef, { recentSends: [...deviceSendsInLastHour, now], lastSentAt: FieldValue.serverTimestamp() });
      }

      tx.set(otpRef, {
        hash: hashOtp(otp, phone),
        expiresAt: new Date(now + OTP_TTL_MS),
        lastSentAt: FieldValue.serverTimestamp(),
        recentSends,
        attempts: 0,
        deviceId,
      });
    });

    await sendWhatsAppOtp(phone, otp);

    return { ok: true, expiresInSeconds: OTP_TTL_MS / 1000 };
  }
);
