import { onCall, HttpsError } from "firebase-functions/v2/https";
import { storeImage } from "../shared/images/store_image";
import { cleanEnum } from "../shared/validation/sanitize";

interface UploadImageInput {
  purpose: "company-logo" | "product" | "category" | "banner" | "learn";
  /** Raw base64 of the image bytes, no data: prefix. */
  data: string;
}

/// Signed-in (non-anonymous) users may upload a company logo for their
/// vendor application; approved vendors may upload product images. The
/// storage folder is derived from the verified token, never from client
/// input, so one account can't write into another's folder.
export const uploadImage = onCall<UploadImageInput>(
  { region: "us-central1", memory: "512MiB" },
  async (request) => {
    const auth = request.auth;
    if (!auth) throw new HttpsError("unauthenticated", "Sign in required.");
    if (auth.token.firebase?.sign_in_provider === "anonymous") {
      throw new HttpsError("permission-denied", "Create an account to upload images.");
    }

    const purpose = cleanEnum(request.data?.purpose, ["company-logo", "product", "category", "banner", "learn"] as const, "purpose");

    let folder: string;
    if (purpose === "company-logo") {
      folder = `companyLogos/${auth.uid}`;
    } else if (purpose === "category" || purpose === "banner" || purpose === "learn") {
      // Admin-managed images; one shared folder per purpose.
      if (auth.token.role !== "super_admin") {
        throw new HttpsError("permission-denied", "Only admins can upload this image.");
      }
      folder = purpose === "category" ? "categoryImages" : purpose === "banner" ? "bannerImages" : "learnThumbnails";
    } else {
      const vendorId = auth.token.vendorId as string | undefined;
      if (auth.token.role !== "vendor" || !vendorId) {
        throw new HttpsError("permission-denied", "Only approved vendors can upload product images.");
      }
      folder = `productImages/${vendorId}`;
    }

    return { url: await storeImage(request.data?.data, folder) };
  },
);
