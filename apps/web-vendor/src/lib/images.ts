import { httpsCallable } from "firebase/functions";
import { functions } from "@/lib/firebase";

export const MAX_SOURCE_BYTES = 10 * 1024 * 1024; // what we'll accept to read
const ACCEPTED_TYPES = ["image/jpeg", "image/png", "image/webp"];
const MAX_EDGE = 1600;
const MIN_EDGE = 64;
const MAX_UPLOAD_BYTES = 1.5 * 1024 * 1024;

export type UploadPurpose = "company-logo" | "product";

const uploadImageCall = httpsCallable<{ purpose: UploadPurpose; data: string }, { url: string }>(
  functions,
  "vendor-uploadImage",
);

function loadBitmap(file: File): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const objectUrl = URL.createObjectURL(file);
    const img = new Image();
    img.onload = () => {
      URL.revokeObjectURL(objectUrl);
      resolve(img);
    };
    img.onerror = () => {
      URL.revokeObjectURL(objectUrl);
      reject(new Error("That file isn't a readable image."));
    };
    img.src = objectUrl;
  });
}

/** Validates the picked file, then re-encodes it through a canvas as JPEG
 * (max 1600px per side). Re-encoding drops EXIF/GPS metadata and any
 * payload hidden in the original file, and keeps uploads small. Returns the
 * JPEG as a blob plus an object URL for preview. */
export async function prepareImage(file: File): Promise<Blob> {
  if (!ACCEPTED_TYPES.includes(file.type)) {
    throw new Error("Use a JPG, PNG or WebP image.");
  }
  if (file.size > MAX_SOURCE_BYTES) {
    throw new Error("Image is too large — pick one under 10 MB.");
  }

  const img = await loadBitmap(file);
  if (img.naturalWidth < MIN_EDGE || img.naturalHeight < MIN_EDGE) {
    throw new Error(`Image is too small — at least ${MIN_EDGE}×${MIN_EDGE} pixels.`);
  }

  const scale = Math.min(1, MAX_EDGE / Math.max(img.naturalWidth, img.naturalHeight));
  const canvas = document.createElement("canvas");
  canvas.width = Math.round(img.naturalWidth * scale);
  canvas.height = Math.round(img.naturalHeight * scale);
  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("Couldn't process the image in this browser.");
  ctx.fillStyle = "#ffffff"; // JPEG has no alpha — flatten transparency onto white
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  ctx.drawImage(img, 0, 0, canvas.width, canvas.height);

  for (const quality of [0.85, 0.7, 0.55]) {
    const blob = await new Promise<Blob | null>((res) => canvas.toBlob(res, "image/jpeg", quality));
    if (blob && blob.size <= MAX_UPLOAD_BYTES) return blob;
  }
  throw new Error("Image is too detailed to compress — try a smaller one.");
}

function blobToBase64(blob: Blob): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve((reader.result as string).split(",")[1] ?? "");
    reader.onerror = () => reject(new Error("Couldn't read the image."));
    reader.readAsDataURL(blob);
  });
}

/** Uploads a prepared image and returns the stored image's URL. */
export async function uploadImage(blob: Blob, purpose: UploadPurpose): Promise<string> {
  const result = await uploadImageCall({ purpose, data: await blobToBase64(blob) });
  return result.data.url;
}
