import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../../shared/firebase";
import { serializeDoc } from "../../shared/orders/order_store";
import { cleanDocId, cleanText } from "../../shared/validation/sanitize";

interface SubmitQuoteRequestInput {
  /// The product being asked about. Required for the request to reach the
  /// vendor's inbox (vendor-listQuoteRequests keys off vendorId, which is
  /// resolved from the product here, never trusted from the client).
  productId?: string;
  /// Legacy clients sent only display strings; still accepted so an old
  /// app build doesn't start failing, but such requests have no vendorId.
  productTitle?: string;
  vendor?: string;
  note: string;
  /// Optional callback number — the vendor needs some way to answer a
  /// guest who has no verified phone on file.
  phone?: string;
}

const E164_PATTERN = /^\+[1-9]\d{6,14}$/;

/// Any signed-in user (anonymous browsing included — see
/// AuthRepository.ensureSignedIn). Writes the quoteRequests doc
/// server-side instead of letting the client write it directly: the uid
/// comes from the verified auth token (request.auth.uid), never a
/// client-supplied field.
export const submitQuoteRequest = onCall<SubmitQuoteRequestInput>({ region: "us-central1" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const uid = request.auth.uid;
  const note = cleanText(request.data?.note, "note", { max: 500, multiline: true });
  const phone = cleanText(request.data?.phone, "phone", { max: 20 });
  if (phone && !E164_PATTERN.test(phone)) {
    throw new HttpsError("invalid-argument", "Phone must be in international format, e.g. +9647501234567.");
  }

  let productId: string | null = null;
  let vendorId: string | null = null;
  let productTitle: string;
  let vendor: string;

  if (request.data?.productId !== undefined) {
    productId = cleanDocId(request.data.productId, "productId");
    const product = (await db.collection("products").doc(productId).get()).data();
    if (!product) throw new HttpsError("not-found", "That product is no longer available.");
    vendorId = product.vendorId as string;
    productTitle = (product.name as string) ?? "";
    vendor = ((await db.collection("vendors").doc(vendorId).get()).data()?.businessName as string) ?? "";
  } else {
    productTitle = cleanText(request.data?.productTitle, "productTitle", { max: 500, min: 1 });
    vendor = cleanText(request.data?.vendor, "vendor", { max: 500, min: 1 });
  }

  const userData = (await db.collection("users").doc(uid).get()).data();

  const requestRef = db.collection("quoteRequests").doc();
  await requestRef.set({
    uid,
    productId,
    vendorId,
    productTitle,
    vendor,
    note,
    customerName: (userData?.name as string) ?? "",
    customerPhone: phone || ((userData?.phone as string) ?? ""),
    status: "submitted",
    response: null,
    createdAt: FieldValue.serverTimestamp(),
  });

  return { requestId: requestRef.id };
});

/// The caller's own quote requests (and any vendor responses), newest
/// first. Sorted in memory to avoid a composite index — a customer has a
/// handful of these, not thousands.
export const listMyQuoteRequests = onCall({ region: "us-central1" }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required.");
  const snap = await db.collection("quoteRequests").where("uid", "==", request.auth.uid).limit(100).get();
  const requests = snap.docs
    .map((d) => serializeDoc(d.id, d.data()))
    .sort((a, b) => ((b.createdAt as number) ?? 0) - ((a.createdAt as number) ?? 0));
  return { requests };
});
