import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db, auth } from "../shared/firebase";
import { consumePasswordSetupToken } from "../shared/auth/password_setup_token";
import { hashPassword, isValidPassword } from "../shared/auth/password";
import { LIMITS, clientIp, enforceRateLimit } from "../shared/rate_limit";

interface SetVendorPasswordInput {
  token: string; // from the /set-password?token=... link in the approval email
  password: string;
}

/// Finalizes the one-time setup link sent by approveVendorApplication:
/// consumes the token (single use, 24h TTL — see password_setup_token.ts),
/// hashes the chosen password, and stores it on users/{uid} — the same hash
/// auth-signIn checks (by username or email). Mirrors signUp's password
/// handling: Firebase Auth itself never gets a password, the hash on
/// users/{uid} is the only credential store.
export const setVendorPassword = onCall<SetVendorPasswordInput>({ region: "us-central1" }, async (request) => {
    await enforceRateLimit(`setpw:${clientIp(request)}`, 20, LIMITS.HOUR);
  const token = request.data?.token?.trim();
  const password = request.data?.password ?? "";

  if (!isValidPassword(password)) {
    throw new HttpsError(
      "invalid-argument",
      "password must be at least 8 characters and include an uppercase letter, a lowercase letter, a number, and a symbol.",
    );
  }

  const { uid } = await consumePasswordSetupToken(token ?? "");

  const userRecord = await auth.getUser(uid);
  if ((userRecord.customClaims?.role as string | undefined) !== "vendor") {
    throw new HttpsError("failed-precondition", "This account is not an approved vendor.");
  }

  const passwordHash = await hashPassword(password);
  await db
    .collection("users")
    .doc(uid)
    .set({ passwordHash, passwordSetAt: FieldValue.serverTimestamp() }, { merge: true });

  const customToken = await auth.createCustomToken(uid);
  return { customToken };
});
