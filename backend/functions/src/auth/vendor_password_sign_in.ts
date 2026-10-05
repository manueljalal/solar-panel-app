import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db, auth } from "../shared/firebase";
import { verifyPassword } from "../shared/auth/password";

interface VendorPasswordSignInInput {
  email: string;
  password: string;
}

/// Email + password sign-in for approved vendors who've set a password
/// via setVendorPassword. Vendors can also always sign in with phone +
/// OTP (verifyPhoneOtp) — this is an additional path, not a replacement;
/// unlike the customer signIn() flow, there's no device step-up here,
/// since the vendor's phone number is already a standing second channel
/// for recovering account access if a password is ever compromised.
export const vendorPasswordSignIn = onCall<VendorPasswordSignInInput>(
  { region: "us-central1" },
  async (request) => {
    const email = request.data?.email?.trim().toLowerCase();
    const password = request.data?.password ?? "";

    if (!email || !password) {
      throw new HttpsError("invalid-argument", "email and password are required.");
    }

    const usersSnap = await db.collection("users").where("email", "==", email).limit(1).get();
    if (usersSnap.empty) {
      // Same message as a wrong password — don't reveal whether the
      // email exists.
      throw new HttpsError("permission-denied", "Incorrect email or password.");
    }

    const userDoc = usersSnap.docs[0];
    const user = userDoc.data();

    if (!user.passwordHash) {
      throw new HttpsError("permission-denied", "Incorrect email or password.");
    }

    const passwordOk = await verifyPassword(password, user.passwordHash as string);
    if (!passwordOk) {
      throw new HttpsError("permission-denied", "Incorrect email or password.");
    }

    await userDoc.ref.update({ lastSignInAt: FieldValue.serverTimestamp() });

    const customToken = await auth.createCustomToken(userDoc.id);
    return { customToken };
  },
);
