import { HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { db } from "../shared/firebase";
import { requireVendor } from "../shared/auth/require_role";
import { cleanDocId } from "../shared/validation/sanitize";

export const COUNTRIES = ["IQ", "CN"] as const;
export type Country = (typeof COUNTRIES)[number];

export interface BulkIdentity {
  uid: string;
  vendorId: string;
  businessName: string;
  country: Country;
  city: string;
  phone: string;
  logoUrl: string;
}

/// Bulk marketplace is for approved vendors only: bulk prices and buyer
/// requests are never exposed to shoppers. Returns the caller's vendor
/// profile fields that get denormalized onto each post (so listing a
/// feed never needs a per-row vendor lookup). Vendors approved before
/// `country` existed default to Iraq.
export async function requireBulkVendor(request: CallableRequest): Promise<BulkIdentity> {
  const { uid, vendorId } = requireVendor(request);
  const snap = await db.collection("vendors").doc(vendorId).get();
  const vendor = snap.data();
  if (!snap.exists || !vendor || vendor.status !== "approved") {
    throw new HttpsError("permission-denied", "Vendor account is not approved.");
  }
  return {
    uid,
    vendorId,
    businessName: vendor.businessName ?? "",
    country: vendor.country === "CN" ? "CN" : "IQ",
    city: vendor.city ?? "",
    phone: vendor.phone ?? "",
    logoUrl: vendor.logoUrl ?? "",
  };
}

/// Positive whole number within [1, max] — quantities are units of
/// product, never fractional.
export function cleanQuantity(value: unknown, field: string, max = 10_000_000): number {
  if (typeof value !== "number" || !Number.isInteger(value) || value < 1 || value > max) {
    throw new HttpsError("invalid-argument", `${field} must be a whole number between 1 and ${max}.`);
  }
  return value;
}

/// Optional category for a post. Must be an existing admin-managed
/// `categories` doc (same list the storefront filters by) — never a
/// free-form value — or null for "no category".
export async function cleanCategoryId(value: unknown): Promise<string | null> {
  if (value === undefined || value === null || value === "") return null;
  const id = cleanDocId(value, "categoryId");
  const snap = await db.collection("categories").doc(id).get();
  if (!snap.exists) {
    throw new HttpsError("invalid-argument", "Unknown category.");
  }
  return id;
}
