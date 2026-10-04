import { HttpsError } from "firebase-functions/v2/https";
import * as crypto from "crypto";
import { db } from "../firebase";

const MAX_ATTEMPTS = 5; // lock the code after this many wrong guesses

function hashOtp(otp: string, phone: string): string {
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
export async function consumePhoneOtp(phone: string, otp: string): Promise<void> {
  const otpRef = db.collection("phoneOtps").doc(phone);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(otpRef);
    if (!snap.exists) {
      throw new HttpsError("not-found", "No code was requested for this number.");
    }

    const data = snap.data()!;
    const expiresAt = data.expiresAt?.toMillis?.() ?? 0;
    if (Date.now() > expiresAt) {
      tx.delete(otpRef);
      throw new HttpsError("deadline-exceeded", "That code has expired. Request a new one.");
    }

    const attempts = (data.attempts ?? 0) as number;
    if (attempts >= MAX_ATTEMPTS) {
      tx.delete(otpRef);
      throw new HttpsError("resource-exhausted", "Too many incorrect attempts. Request a new code.");
    }

    const expectedHash = Buffer.from(data.hash as string, "hex");
    const actualHash = Buffer.from(hashOtp(otp, phone), "hex");
    // Constant-time compare (crypto.timingSafeEqual), not `===` — this is
    // exactly the kind of secret-comparison where a timing side-channel
    // is a real (if narrow) risk.
    const matches = expectedHash.length === actualHash.length && crypto.timingSafeEqual(expectedHash, actualHash);

    if (!matches) {
      tx.update(otpRef, { attempts: attempts + 1 });
      throw new HttpsError("permission-denied", "Incorrect code.");
    }

    tx.delete(otpRef);
  });
}
