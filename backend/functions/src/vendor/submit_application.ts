import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../shared/firebase";

interface PickedLocationInput {
  latitude: number;
  longitude: number;
  address: string;
}

interface SubmitApplicationInput {
  businessName: string;
  city: string;
  address: string;
  phone: string;
  email: string;
  note: string;
  location: PickedLocationInput;
}

const MAX_STRING_LENGTH = 500;
const MAX_EMAIL_LENGTH = 254;
const E164_PATTERN = /^\+[1-9]\d{6,14}$/;
// Intentionally simple — RFC 5322 is not worth replicating here; this
// catches typos and obviously-malformed input, the email itself is
// confirmed to work once the approval email actually lands.
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/// Any signed-in user may apply to become a vendor (see Account tab's
/// "Own a solar business? Apply" and the web vendor portal's /apply
/// page). Writes the vendorApplications doc server-side instead of the
/// client writing it directly — uid comes from the verified auth token,
/// never a client-supplied field.
export const submitApplication = onCall<SubmitApplicationInput>({ region: "us-central1" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const uid = request.auth.uid;

  const businessName = request.data?.businessName?.trim();
  const city = request.data?.city?.trim();
  const address = request.data?.address?.trim() ?? "";
  const phone = request.data?.phone?.trim();
  const email = request.data?.email?.trim().toLowerCase();
  const note = request.data?.note?.trim() ?? "";
  const location = request.data?.location ?? null;

  if (!businessName || !city || !phone || !email) {
    throw new HttpsError("invalid-argument", "businessName, city, phone, and email are required.");
  }
  if (!E164_PATTERN.test(phone)) {
    throw new HttpsError("invalid-argument", "phone must be in E.164 format, e.g. +9647501234567.");
  }
  if (!EMAIL_PATTERN.test(email) || email.length > MAX_EMAIL_LENGTH) {
    throw new HttpsError("invalid-argument", "Enter a valid email address.");
  }
  for (const [key, value] of [
    ["businessName", businessName],
    ["city", city],
    ["address", address],
    ["note", note],
  ] as const) {
    if (value.length > MAX_STRING_LENGTH) {
      throw new HttpsError("invalid-argument", `${key} exceeds ${MAX_STRING_LENGTH} characters.`);
    }
  }

  const applicationRef = db.collection("vendorApplications").doc();
  await applicationRef.set({
    uid,
    businessName,
    city,
    address,
    phone,
    email,
    note,
    location,
    status: "pending",
    createdAt: FieldValue.serverTimestamp(),
  });

  return { applicationId: applicationRef.id };
});
