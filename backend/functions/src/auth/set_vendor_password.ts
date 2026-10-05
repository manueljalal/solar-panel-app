import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { hashPassword, isValidPassword } from "../shared/auth/password";
import { consumePasswordSetupToken } from "../shared/auth/password_setup_token";

interface SetVendorPasswordInput {
  token: string;
  password: string;
}

/// Consumes a one-time setup token (minted by approveVendorApplication and
/// delivered via the approval email) to set a password on the vendor's
/// users/{uid} doc. No Firebase Auth session is required — the token
/// itself, proven by its hash matching a stored, unexpired, unused
/// record, is the only credential needed here, the same trust model
/// signUp() uses for its own bcrypt-hashed passwordHash field.
export const setVendorPassword = onCall<SetVendorPasswordInput>({ region: "us-central1" }, async (request) => {
  const token = request.data?.token?.trim();
  const password = request.data?.password ?? "";

  if (!token) {
    throw new HttpsError("invalid-argument", "token is required.");
  }
  if (!isValidPassword(password)) {
    throw new HttpsError(
      "invalid-argument",
      "password must be at least 8 characters and include an uppercase letter, a lowercase letter, a number, and a symbol.",
    );
  }

  const consumed = await consumePasswordSetupToken(token);
  if (!consumed) {
    throw new HttpsError("failed-precondition", "This link is invalid or has expired.");
  }

  const passwordHash = await hashPassword(password);
  await db.collection("users").doc(consumed.vendorUid).set(
    {
      passwordHash,
      passwordSetAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return { ok: true };
});
