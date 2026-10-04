import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../../shared/firebase";

interface SubmitQuoteRequestInput {
  productTitle: string;
  vendor: string;
  note: string;
}

const MAX_STRING_LENGTH = 500;

/// Any signed-in user (anonymous browsing included — see
/// AuthRepository.ensureSignedIn). Writes the quoteRequests doc
/// server-side instead of letting the client write it directly: the uid
/// comes from the verified auth token (request.auth.uid), never a
/// client-supplied field, which is the whole reason this goes through a
/// callable rather than a direct Firestore write under the owner-scoped
/// create rule.
export const submitQuoteRequest = onCall<SubmitQuoteRequestInput>({ region: "us-central1" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const uid = request.auth.uid;

  const productTitle = request.data?.productTitle?.trim();
  const vendor = request.data?.vendor?.trim();
  const note = request.data?.note?.trim() ?? "";

  if (!productTitle || !vendor) {
    throw new HttpsError("invalid-argument", "productTitle and vendor are required.");
  }
  if (productTitle.length > MAX_STRING_LENGTH || vendor.length > MAX_STRING_LENGTH || note.length > MAX_STRING_LENGTH) {
    throw new HttpsError("invalid-argument", `Fields must be under ${MAX_STRING_LENGTH} characters.`);
  }

  const requestRef = db.collection("quoteRequests").doc();
  await requestRef.set({
    uid,
    productTitle,
    vendor,
    note,
    status: "submitted",
    createdAt: FieldValue.serverTimestamp(),
  });

  return { requestId: requestRef.id };
});
