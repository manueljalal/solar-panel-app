import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { requireVendor } from "../shared/auth/require_role";
import { isOwnedImageUrl } from "../shared/images/store_image";
import { cleanText } from "../shared/validation/sanitize";

interface UpdateProfileInput {
  businessName: string;
  city: string;
  address?: string;
  description?: string;
  /** From vendor-uploadImage (purpose "company-logo"); omit to keep the current one. */
  logoUrl?: string;
}

/// Vendor edits its public company profile (shown on the company page and
/// next to its products and B2B posts). The phone stays fixed: it is the
/// account's verified login number.
export const updateProfile = onCall<UpdateProfileInput>({ region: "us-central1" }, async (request) => {
  const { uid, vendorId } = requireVendor(request);
  const businessName = cleanText(request.data?.businessName, "businessName", { max: 120, min: 1 });
  const city = cleanText(request.data?.city, "city", { max: 80, min: 1 });
  const address = cleanText(request.data?.address, "address", { max: 300 });
  const description = cleanText(request.data?.description, "description", { max: 1000, multiline: true });

  const update: Record<string, unknown> = {
    businessName, city, address, description, updatedAt: FieldValue.serverTimestamp(),
  };
  const logoUrl = request.data?.logoUrl;
  if (logoUrl) {
    if (!isOwnedImageUrl(logoUrl, `companyLogos/${uid}`)) {
      throw new HttpsError("invalid-argument", "Upload the logo through the portal first.");
    }
    update.logoUrl = logoUrl;
  }
  await db.collection("vendors").doc(vendorId).update(update);
  return { ok: true };
});
