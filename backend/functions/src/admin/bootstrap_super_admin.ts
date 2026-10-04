import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db, auth } from "../shared/firebase";

/// Solves the chicken-and-egg problem of role-based admin functions:
/// nobody can call approveVendorApplication until someone has the
/// super_admin claim, and nobody can grant that claim without already
/// being an admin. This callable grants super_admin to WHOEVER CALLS IT
/// — but only once, ever, tracked by a system/bootstrap Firestore doc.
/// After the first successful call it permanently refuses. This is the
/// standard escape hatch for this problem; there is no way to make it
/// safe AND self-service beyond "first caller wins, then it's welded
/// shut" — after bootstrapping, grant further admins via the Firebase
/// console's custom-claims tooling or a future admin-only "promote"
/// callable, not this function.
export const bootstrapSuperAdmin = onCall({ region: "us-central1" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const bootstrapRef = db.collection("system").doc("bootstrap");

  const alreadyDone = await db.runTransaction(async (tx) => {
    const snap = await tx.get(bootstrapRef);
    if (snap.exists && snap.data()!.superAdminBootstrapped) {
      return true;
    }
    tx.set(bootstrapRef, { superAdminBootstrapped: true, bootstrappedUid: request.auth!.uid }, { merge: true });
    return false;
  });

  if (alreadyDone) {
    throw new HttpsError(
      "failed-precondition",
      "A super_admin has already been bootstrapped. Ask an existing admin to promote you instead."
    );
  }

  const user = await auth.getUser(request.auth.uid);
  await auth.setCustomUserClaims(request.auth.uid, { ...user.customClaims, role: "super_admin" });

  return { ok: true };
});
