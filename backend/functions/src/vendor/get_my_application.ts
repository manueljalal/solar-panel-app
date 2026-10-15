import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db } from "../shared/firebase";

/// Signed-in callers only. Returns the caller's most recent vendor
/// application (status + business name) or null if they never applied —
/// the mobile apply screen uses it to show "pending" / "approved" instead
/// of a blank form. Sorted in memory (a few rows per user) so no
/// uid+createdAt composite index is needed.
export const getMyApplication = onCall({ region: "us-central1" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const snap = await db.collection("vendorApplications").where("uid", "==", request.auth.uid).limit(20).get();
  if (snap.empty) return { application: null };

  const newest = snap.docs
    .map((d) => d.data())
    .sort((a, b) => (b.createdAt?.toMillis?.() ?? 0) - (a.createdAt?.toMillis?.() ?? 0))[0];

  return {
    application: {
      status: newest.status as string,
      businessName: (newest.businessName as string) ?? "",
    },
  };
});
