// Removes the mock data created by scripts/seed-firestore.mjs from Firestore.
// Deletes ONLY these fixed document ids — real vendors/products are untouched.
//
// Run: node scripts/remove-seed-data.mjs
// Uses Application Default Credentials, same as the seed script.

import { initializeApp, applicationDefault } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

initializeApp({ credential: applicationDefault(), projectId: "flutter-firebase-connect-ec83e" });
const db = getFirestore();

const productIds = ["tiger-neo-450w", "hiku6-400w", "luna2000-battery", "growatt-hybrid-inverter"];
const vendorIds = ["sunbridge-energy", "helios-power-co", "greentech-iraq"];

for (const id of productIds) {
  await db.collection("products").doc(id).delete();
  console.log("deleted products/" + id);
}
for (const id of vendorIds) {
  await db.collection("vendors").doc(id).delete();
  console.log("deleted vendors/" + id);
}
