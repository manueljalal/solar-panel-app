import { initializeApp, getApps } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";

// One shared Admin SDK app instance across all function modules — avoids
// re-initializing per cold start when multiple functions from this
// codebase run in the same container.
if (getApps().length === 0) {
  initializeApp();
}

export const db = getFirestore();
export const auth = getAuth();
