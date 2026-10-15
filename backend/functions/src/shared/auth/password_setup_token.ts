import { HttpsError } from "firebase-functions/v2/https";
import { randomBytes, createHash, timingSafeEqual } from "crypto";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../firebase";

const TOKEN_BYTES = 32; // 256 bits — the token itself is the credential, not a 6-digit code, so it needs full entropy
const TOKEN_TTL_MS = 24 * 60 * 60 * 1000; // matches the "This link expires in 24 hours" copy in the approval email

function hashToken(token: string): string {
  // The raw token lives only in the emailed URL and the caller's request —
  // never store it as-is, same reasoning as phoneOtps' hashed codes.
  return createHash("sha256").update(token).digest("hex");
}

/// Mints a one-time password-setup token for `uid` and records its hash on
/// passwordSetupTokens/{tokenId} — called once, right after a vendor
/// application is approved (see approve_vendor_application.ts), so the
/// resulting link can be emailed. The raw token is returned here and never
/// persisted; only its hash is stored, and consumePasswordSetupToken
/// deletes the doc on first successful use.
export async function createPasswordSetupToken(uid: string): Promise<string> {
  const token = randomBytes(TOKEN_BYTES).toString("hex");
  const tokenId = createHash("sha256").update(token).digest("hex").slice(0, 32);

  await db
    .collection("passwordSetupTokens")
    .doc(tokenId)
    .set({
      uid,
      tokenHash: hashToken(token),
      expiresAt: new Date(Date.now() + TOKEN_TTL_MS),
      createdAt: FieldValue.serverTimestamp(),
    });

  return token;
}

/// Verifies `token` against the stored hash and consumes it (deletes the
/// doc) on success, so a setup link can't be replayed. Throws HttpsError on
/// any failure (not found / expired / malformed) — callers don't need
/// their own error handling, matching consumePhoneOtp's contract.
export async function consumePasswordSetupToken(token: string): Promise<{ uid: string }> {
  if (!token) {
    throw new HttpsError("invalid-argument", "token is required.");
  }
  const tokenId = createHash("sha256").update(token).digest("hex").slice(0, 32);
  const tokenRef = db.collection("passwordSetupTokens").doc(tokenId);

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(tokenRef);
    if (!snap.exists) {
      throw new HttpsError("not-found", "This setup link is invalid or has already been used.");
    }

    const data = snap.data()!;
    const expiresAt = (data.expiresAt as { toMillis?: () => number })?.toMillis?.() ?? 0;
    if (Date.now() > expiresAt) {
      tx.delete(tokenRef);
      throw new HttpsError("deadline-exceeded", "This setup link has expired. Ask an admin to resend it.");
    }

    const expectedHash = Buffer.from(data.tokenHash as string, "hex");
    const actualHash = Buffer.from(hashToken(token), "hex");
    const matches = expectedHash.length === actualHash.length && timingSafeEqual(expectedHash, actualHash);
    if (!matches) {
      // tokenId is itself derived from the token, so a mismatch here would
      // mean a hash collision on the id, not a wrong guess — treat it the
      // same as not-found rather than leaking which branch failed.
      throw new HttpsError("not-found", "This setup link is invalid or has already been used.");
    }

    tx.delete(tokenRef);
    return { uid: data.uid as string };
  });
}
