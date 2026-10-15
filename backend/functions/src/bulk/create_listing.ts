import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { cleanMultilingual, cleanPrice, cleanText, primaryText, type MultilingualText } from "../shared/validation/sanitize";
import { isOwnedImageUrl } from "../shared/images/store_image";
import { cleanCategoryId, cleanQuantity, requireBulkVendor } from "./shared";

interface TierInput {
  minQty: number;
  unitPriceUsd: number;
}

interface CreateListingInput {
  /** Per-language text, any subset of en/ar/ku (a plain string = English). */
  title: MultilingualText | string;
  description?: MultilingualText | string;
  /** URL from vendor-uploadImage (purpose "product"). Optional. */
  imageUrl?: string;
  unit: string;
  categoryId?: string | null;
  tiers: TierInput[];
}

const MAX_TIERS = 5;

/// Vendor-only. Posts a wholesale listing: a product offered in bulk with
/// quantity-tier pricing (e.g. 100+ units = $X, 500+ = $Y). Visible only
/// to other approved vendors via bulk-listListings.
export const createListing = onCall<CreateListingInput>({ region: "us-central1" }, async (request) => {
  const me = await requireBulkVendor(request);

  const titleI18n = cleanMultilingual(request.data?.title, "title", { max: 120 });
  const descriptionI18n = cleanMultilingual(request.data?.description, "description", {
    max: 1000,
    multiline: true,
    optional: true,
  });
  const imageUrl = request.data?.imageUrl;
  if (imageUrl && !isOwnedImageUrl(imageUrl, `productImages/${me.vendorId}`)) {
    throw new HttpsError("invalid-argument", "Upload the photo through the app first.");
  }
  const unit = cleanText(request.data?.unit || "pcs", "unit", { max: 20, min: 1 });
  const categoryId = await cleanCategoryId(request.data?.categoryId);

  const rawTiers = request.data?.tiers;
  if (!Array.isArray(rawTiers) || rawTiers.length < 1 || rawTiers.length > MAX_TIERS) {
    throw new HttpsError("invalid-argument", `Add between 1 and ${MAX_TIERS} price tiers.`);
  }
  const tiers = rawTiers
    .map((t, i) => {
      if (typeof t !== "object" || t === null) throw new HttpsError("invalid-argument", `tier ${i + 1} is invalid.`);
      return {
        minQty: cleanQuantity((t as TierInput).minQty, `tier ${i + 1} quantity`),
        unitPriceUsd: cleanPrice((t as TierInput).unitPriceUsd, `tier ${i + 1} price`),
      };
    })
    .sort((a, b) => a.minQty - b.minQty);
  for (let i = 1; i < tiers.length; i++) {
    if (tiers[i].minQty === tiers[i - 1].minQty) {
      throw new HttpsError("invalid-argument", "Each price tier needs a different quantity.");
    }
  }

  const ref = db.collection("bulkListings").doc();
  await ref.set({
    vendorId: me.vendorId,
    ownerUid: me.uid,
    businessName: me.businessName,
    country: me.country,
    city: me.city,
    phone: me.phone,
    logoUrl: me.logoUrl,
    categoryId,
    title: primaryText(titleI18n),
    titleI18n,
    description: primaryText(descriptionI18n),
    descriptionI18n,
    imageUrl: imageUrl || null,
    unit,
    tiers,
    moq: tiers[0].minQty,
    status: "active",
    createdAt: FieldValue.serverTimestamp(),
  });
  return { id: ref.id };
});
