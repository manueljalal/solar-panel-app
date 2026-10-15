import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { cleanMultilingual, cleanPrice, cleanText, primaryText, type MultilingualText } from "../shared/validation/sanitize";
import { isOwnedImageUrl } from "../shared/images/store_image";
import { cleanCategoryId, cleanQuantity, requireBulkVendor } from "./shared";

interface CreateRequestInput {
  /** Per-language text, any subset of en/ar/ku (a plain string = English). */
  title: MultilingualText | string;
  description?: MultilingualText | string;
  /** URL from vendor-uploadImage (purpose "product"). Optional. */
  imageUrl?: string;
  quantity: number;
  unit: string;
  categoryId?: string | null;
  targetPriceUsd?: number | null;
  deliveryCity?: string;
}

/// Vendor-only. A buyer request ("I need 500 x 450W panels") that other
/// approved vendors — Iraqi or Chinese — can answer by contacting the
/// poster. targetPriceUsd is optional: many buyers want quotes, not to
/// anchor a price.
export const createRequest = onCall<CreateRequestInput>({ region: "us-central1" }, async (request) => {
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
  const quantity = cleanQuantity(request.data?.quantity, "quantity");
  const deliveryCity = cleanText(request.data?.deliveryCity, "deliveryCity", { max: 80 });

  const rawTarget = request.data?.targetPriceUsd;
  let targetPriceUsd: number | null = null;
  if (rawTarget !== undefined && rawTarget !== null) {
    targetPriceUsd = cleanPrice(rawTarget, "targetPriceUsd");
  }

  const ref = db.collection("bulkRequests").doc();
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
    quantity,
    targetPriceUsd,
    deliveryCity,
    status: "open",
    createdAt: FieldValue.serverTimestamp(),
  });
  return { id: ref.id };
});
