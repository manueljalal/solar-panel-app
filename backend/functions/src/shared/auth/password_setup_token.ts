import * as crypto from "crypto";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../firebase";

const TOKEN_BYTES = 32; // 256 bits — not brute-forceable, unlike a 6-digit OTP
const TOKEN_TTL_MS = 24 * 60 * 60 * 1000; // 24h, generous since this is a one-time onboarding action

function hashToken(token: string): string {
  return crypto.createHash("sha256").update(token).digest("hex");
}

/// Creates a one-time password-setup token for a just-approved vendor.
/// The raw token is only ever returned here (to embed in the approval
/// email's link) — what's persisted is its hash, so a Firestore read
/// alone can't be used to set someone else's password.
export async function createPasswordSetupToken(vendorUid: string): Promise<string> {
  const token = crypto.randomBytes(TOKEN_BYTES).toString("base64url");
  await db
    .collection("vendorPasswordSetupTokens")
    .doc(hashToken(token))
    .set({
      vendorUid,
      createdAt: FieldValue.serverTimestamp(),
      expiresAt: new Date(Date.now() + TOKEN_TTL_MS),
      usedAt: null,
    });
  return token;
}

export interface ConsumedToken {
  vendorUid: string;
}

/// Validates and immediately invalidates a setup token (single use).
/// Returns the vendor uid it was issued for, or null if the token is
/// missing, expired, or already used — callers return a generic "invalid
/// or expired link" rather than distinguishing these, so a guessed token
/// id can't be used to probe which case applies.
export async function consumePasswordSetupToken(token: string): Promise<ConsumedToken | null> {
  const tokenRef = db.collection("vendorPasswordSetupTokens").doc(hashToken(token));

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(tokenRef);
    if (!snap.exists) return null;

    const data = snap.data()!;
    if (data.usedAt) return null;

    const expiresAt = data.expiresAt?.toMillis?.() ?? 0;
    if (Date.now() > expiresAt) return null;

    tx.update(tokenRef, { usedAt: FieldValue.serverTimestamp() });
    return { vendorUid: data.vendorUid as string };
  });
}
