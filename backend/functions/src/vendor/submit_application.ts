import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { isOwnedImageUrl } from "../shared/images/store_image";
import { cleanEmail, cleanEnum, cleanText } from "../shared/validation/sanitize";

interface PickedLocationInput {
  latitude: number;
  longitude: number;
  address: string;
}

interface SubmitApplicationInput {
  businessName: string;
  city: string;
  address: string;
  email: string;
  note: string;
  /** Company's home country — Iraqi or Chinese companies trade here. */
  country?: "IQ" | "CN";
  /** URL returned by vendor-uploadImage (purpose "company-logo"). */
  logoUrl: string;
  location: PickedLocationInput | null;
}

const E164_PATTERN = /^\+[1-9]\d{6,14}$/;
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

  const userSnap = await db.collection("users").doc(uid).get();
  const phone = userSnap.data()?.phone?.trim();
  if (!phone) {
    throw new HttpsError("failed-precondition", "A verified phone number is required to apply.");
  }
  if (!E164_PATTERN.test(phone)) {
    throw new HttpsError("internal", "Verified phone number is malformed.");
  }

  const businessName = cleanText(request.data?.businessName, "businessName", { max: 120, min: 1 });
  const city = cleanText(request.data?.city, "city", { max: 80, min: 1 });
  const address = cleanText(request.data?.address, "address", { max: 300 });
  const email = cleanEmail(request.data?.email);
  const country = cleanEnum(request.data?.country ?? "IQ", ["IQ", "CN"] as const, "country");
  const note = cleanText(request.data?.note, "note", { max: 1000, multiline: true });

  // Only a URL our own upload endpoint issued for THIS account's folder is
  // accepted — never an arbitrary external URL.
  const logoUrl = request.data?.logoUrl;
  if (!isOwnedImageUrl(logoUrl, `companyLogos/${uid}`)) {
    throw new HttpsError("invalid-argument", "Upload an image of your company.");
  }

  const rawLocation = request.data?.location;
  let location: PickedLocationInput | null = null;
  if (rawLocation) {
    const { latitude, longitude } = rawLocation;
    if (
      typeof latitude !== "number" || typeof longitude !== "number" ||
      !(latitude >= -90 && latitude <= 90) || !(longitude >= -180 && longitude <= 180)
    ) {
      throw new HttpsError("invalid-argument", "location is invalid.");
    }
    location = { latitude, longitude, address: cleanText(rawLocation.address, "location address", { max: 300 }) };
  }

  const applicationRef = db.collection("vendorApplications").doc();
  await applicationRef.set({
    uid,
    businessName,
    city,
    address,
    phone,
    email,
    country,
    note,
    logoUrl,
    location,
    status: "pending",
    createdAt: FieldValue.serverTimestamp(),
  });

  return { applicationId: applicationRef.id };
});
