import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { requireVendor } from "../shared/auth/require_role";
import { isOwnedImageUrl } from "../shared/images/store_image";
import { cleanText } from "../shared/validation/sanitize";

interface UpdateProfileInput {
  businessName?: string;
  city?: string;
  address?: string;
  phone?: string;
  description?: string;
  /** URL returned by vendor-uploadImage (purpose "company-logo"). */
  logoUrl?: string;
}

const E164_PATTERN = /^\+[1-9]\d{6,14}$/;

/// Vendor-only: edit the caller's own public vendors/{vendorId} profile
/// after approval. Only the fields sent are changed. Status, rating,
/// ownership and country stay admin/system-controlled.
export const updateProfile = onCall<UpdateProfileInput>({ region: "us-central1" }, async (request) => {
  const { uid, vendorId } = requireVendor(request);
  const input = request.data ?? {};
  const update: Record<string, unknown> = {};

  if (input.businessName !== undefined) update.businessName = cleanText(input.businessName, "Business name", { max: 120, min: 1 });
  if (input.city !== undefined) update.city = cleanText(input.city, "City", { max: 80, min: 1 });
  if (input.address !== undefined) update.address = cleanText(input.address, "Address", { max: 300 }) || null;
  if (input.description !== undefined) {
    update.description = cleanText(input.description, "Description", { max: 2000, multiline: true }) || null;
  }
  if (input.phone !== undefined) {
    const phone = cleanText(input.phone, "Phone", { max: 20, min: 1 });
    if (!E164_PATTERN.test(phone)) {
      throw new HttpsError("invalid-argument", "Phone must be in international format, e.g. +9647501234567.");
    }
    update.phone = phone;
  }
  if (input.logoUrl !== undefined) {
    if (!isOwnedImageUrl(input.logoUrl, `companyLogos/${uid}`)) {
      throw new HttpsError("invalid-argument", "Upload the logo first.");
    }
    update.logoUrl = input.logoUrl;
  }
  if (Object.keys(update).length === 0) {
    throw new HttpsError("invalid-argument", "Nothing to update.");
  }

  const ref = db.collection("vendors").doc(vendorId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "Vendor profile not found.");
  await ref.update({ ...update, updatedAt: FieldValue.serverTimestamp() });
  return { ok: true };
});
