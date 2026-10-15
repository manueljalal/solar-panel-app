import { randomUUID } from "crypto";
import { getStorage } from "firebase-admin/storage";
import { HttpsError } from "firebase-functions/v2/https";
import "../firebase"; // ensures the Admin app is initialized

export const MAX_IMAGE_BYTES = 2 * 1024 * 1024;
const MAX_DIMENSION = 4096;
const MIN_DIMENSION = 64;

interface Detected {
  contentType: "image/jpeg" | "image/png";
  extension: "jpg" | "png";
  width: number;
  height: number;
}

/// Identifies the image from its actual bytes — the client-declared
/// content type and file name are never trusted. Only JPEG and PNG are
/// accepted (SVG can carry script; GIF/WebP aren't needed). Dimensions are
/// read from the header, which also proves the file is structurally an
/// image rather than e.g. an HTML file with a renamed extension.
function detectImage(buf: Buffer): Detected | null {
  // PNG: 8-byte signature, then the IHDR chunk with width/height.
  if (buf.length > 24 && buf.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) {
    if (buf.toString("ascii", 12, 16) !== "IHDR") return null;
    return { contentType: "image/png", extension: "png", width: buf.readUInt32BE(16), height: buf.readUInt32BE(20) };
  }

  // JPEG: walk marker segments until a Start-Of-Frame carries the size.
  if (buf.length > 4 && buf[0] === 0xff && buf[1] === 0xd8 && buf[2] === 0xff) {
    let pos = 2;
    while (pos + 4 <= buf.length) {
      if (buf[pos] !== 0xff) return null;
      const marker = buf[pos + 1];
      if (marker === 0xff) {
        pos += 1; // fill byte
        continue;
      }
      if (marker === 0xd8 || marker === 0x01 || (marker >= 0xd0 && marker <= 0xd7)) {
        pos += 2; // standalone markers carry no length
        continue;
      }
      const isSof = marker >= 0xc0 && marker <= 0xcf && marker !== 0xc4 && marker !== 0xc8 && marker !== 0xcc;
      if (isSof) {
        if (pos + 9 > buf.length) return null;
        return { contentType: "image/jpeg", extension: "jpg", height: buf.readUInt16BE(pos + 5), width: buf.readUInt16BE(pos + 7) };
      }
      pos += 2 + buf.readUInt16BE(pos + 2);
    }
  }
  return null;
}

function downloadUrl(bucketName: string, path: string, token: string): string {
  return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;
}

/// Validates a base64-encoded image and stores it under `${folder}/` in
/// the default bucket with an unguessable name. Returns the public
/// download URL. The server picks the path and extension; the client
/// supplies only the bytes.
export async function storeImage(base64: unknown, folder: string): Promise<string> {
  if (typeof base64 !== "string" || base64.length === 0) {
    throw new HttpsError("invalid-argument", "An image is required.");
  }
  // base64 inflates by 4/3 — reject oversized input before decoding.
  if (base64.length > Math.ceil((MAX_IMAGE_BYTES * 4) / 3) + 8) {
    throw new HttpsError("invalid-argument", "Image is too large (max 2 MB).");
  }
  if (!/^[A-Za-z0-9+/]+={0,2}$/.test(base64)) {
    throw new HttpsError("invalid-argument", "Image data is malformed.");
  }

  const buf = Buffer.from(base64, "base64");
  if (buf.length === 0 || buf.length > MAX_IMAGE_BYTES) {
    throw new HttpsError("invalid-argument", "Image is too large (max 2 MB).");
  }

  const image = detectImage(buf);
  if (!image) {
    throw new HttpsError("invalid-argument", "Only JPEG or PNG images are allowed.");
  }
  if (
    image.width < MIN_DIMENSION || image.height < MIN_DIMENSION ||
    image.width > MAX_DIMENSION || image.height > MAX_DIMENSION
  ) {
    throw new HttpsError("invalid-argument", `Image must be between ${MIN_DIMENSION} and ${MAX_DIMENSION} pixels per side.`);
  }

  const bucket = getStorage().bucket();
  const path = `${folder}/${randomUUID()}.${image.extension}`;
  const token = randomUUID();
  await bucket.file(path).save(buf, {
    resumable: false,
    contentType: image.contentType,
    metadata: {
      cacheControl: "public, max-age=31536000, immutable",
      contentDisposition: "inline",
      metadata: { firebaseStorageDownloadTokens: token },
    },
  });
  return downloadUrl(bucket.name, path, token);
}

/// True only for URLs that storeImage produced for exactly this folder.
/// Callables that accept an image URL from the client must check this —
/// otherwise a vendor could point their product at any external URL
/// (tracking pixels, hotlinked or malicious content) or at another
/// vendor's folder.
export function isOwnedImageUrl(url: unknown, folder: string): url is string {
  if (typeof url !== "string" || url.length > 1024) return false;
  const bucketName = getStorage().bucket().name;
  const prefix = `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodeURIComponent(folder + "/")}`;
  if (!url.startsWith(prefix)) return false;
  return new RegExp(`^${prefix.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}[0-9a-f-]{36}\\.(jpg|png)\\?alt=media&token=[0-9a-f-]{36}$`).test(url);
}
