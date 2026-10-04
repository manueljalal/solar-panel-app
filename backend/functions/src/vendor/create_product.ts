import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { requireVendor } from "../shared/auth/require_role";

interface CreateProductInput {
  category: "residential" | "commercial" | "battery" | "inverter";
  brand: string;
  name: string;
  spec: string;
  wattage?: number;
  price: number;
  currency: "USD" | "IQD";
  imageUrl: string;
  description?: string;
  warranty?: string;
}

const MAX_STRING_LENGTH = 500; // basic abuse/perf guard, not just validation

function assertReasonableStrings(input: CreateProductInput) {
  for (const [key, value] of Object.entries(input)) {
    if (typeof value === "string" && value.length > MAX_STRING_LENGTH) {
      throw new HttpsError("invalid-argument", `${key} exceeds ${MAX_STRING_LENGTH} characters.`);
    }
  }
}

/// Vendor-only. This is the actual "upload a product" operation — the
/// piece that was completely missing before: every product in Firestore
/// until now came from a one-off seed script, not from a real vendor.
export const createProduct = onCall<CreateProductInput>({ region: "us-central1" }, async (request) => {
  const { vendorId } = requireVendor(request);
  const input = request.data;

  if (!input.name || !input.brand || !input.category || typeof input.price !== "number") {
    throw new HttpsError("invalid-argument", "name, brand, category, and price are required.");
  }
  if (input.price <= 0 || input.price > 1_000_000) {
    throw new HttpsError("invalid-argument", "price must be a sane positive number.");
  }
  assertReasonableStrings(input);

  const productRef = db.collection("products").doc();
  await productRef.set({
    vendorId,
    category: input.category,
    brand: input.brand,
    name: input.name,
    spec: input.spec ?? "",
    wattage: input.wattage ?? null,
    price: input.price,
    currency: input.currency ?? "USD",
    inStock: true,
    rating: 0,
    sold: 0,
    warranty: input.warranty ?? null,
    description: input.description ?? null,
    imageUrl: input.imageUrl ?? "",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  return { productId: productRef.id };
});
