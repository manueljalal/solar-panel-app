import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db, auth } from "../shared/firebase";
import { verifyPassword } from "../shared/auth/password";

interface VendorPasswordSignInInput {
  email: string;
  password: string;
}

/// Email + password sign-in for already-approved vendors (set via the
/// /set-password link in the approval email — see set_vendor_password.ts).
/// Looked up by email rather than username: vendors never go through
/// signUp, so they have no entry in the `usernames` collection — email is
/// denormalized onto users/{uid} by approveVendorApplication specifically
/// so this lookup works. Phone + WhatsApp OTP (auth-verifyPhoneOtp) stays
/// available as the fallback/recovery path, same account either way.
export const vendorPasswordSignIn = onCall<VendorPasswordSignInInput>({ region: "us-central1" }, async (request) => {
  const email = request.data?.email?.trim().toLowerCase();
  const password = request.data?.password ?? "";

  if (!email || !password) {
    throw new HttpsError("invalid-argument", "email and password are required.");
  }

  const usersSnap = await db.collection("users").where("email", "==", email).limit(1).get();
  if (usersSnap.empty) {
    // Same message as a wrong password — don't reveal whether the email exists.
    throw new HttpsError("permission-denied", "Incorrect email or password.");
  }
  const userDoc = usersSnap.docs[0];
  const user = userDoc.data();

  const passwordHash = user.passwordHash as string | undefined;
  if (!passwordHash) {
    throw new HttpsError("permission-denied", "Incorrect email or password.");
  }

  const passwordOk = await verifyPassword(password, passwordHash);
  if (!passwordOk) {
    throw new HttpsError("permission-denied", "Incorrect email or password.");
  }

  const userRecord = await auth.getUser(userDoc.id);
  if ((userRecord.customClaims?.role as string | undefined) !== "vendor") {
    throw new HttpsError("permission-denied", "This account is not an approved vendor.");
  }

  await userDoc.ref.update({ lastSignInAt: FieldValue.serverTimestamp() });

  const customToken = await auth.createCustomToken(userDoc.id);
  return { customToken };
});
