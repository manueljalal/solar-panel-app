// Deletes one Solary account by phone — the same steps as the admin
// console's Delete account (admin-deleteAccount). Without --confirm it only
// prints what it found.
//
//   node delete-account.mjs +9647501234567            # look up only
//   node delete-account.mjs +9647501234567 --confirm  # delete
import { initializeApp, applicationDefault } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";

const PROJECT_ID = "flutter-firebase-connect-ec83e";
const phone = process.argv[2];
const confirm = process.argv.includes("--confirm");
if (!/^\+[1-9]\d{6,14}$/.test(phone ?? "")) {
  console.error("Usage: node delete-account.mjs +9647501234567 [--confirm]");
  process.exit(1);
}

initializeApp({ credential: applicationDefault(), projectId: PROJECT_ID });
const auth = getAuth();
const db = getFirestore();

const authUser = await auth.getUserByPhoneNumber(phone).catch(() => null);
const profileByPhone = await db.collection("users").where("phone", "==", phone).get();
const uids = new Set([authUser?.uid, ...profileByPhone.docs.map((d) => d.id)].filter(Boolean));

if (uids.size === 0) {
  console.log(`No account uses ${phone}.`);
  process.exit(0);
}

for (const uid of uids) {
  const user = await auth.getUser(uid).catch(() => null);
  const profile = await db.collection("users").doc(uid).get();
  const vendors = await db.collection("vendors").where("ownerUid", "==", uid).get();
  const apps = await db.collection("vendorApplications").where("uid", "==", uid).get();
  const names = await db.collection("usernames").where("uid", "==", uid).get();
  const role = user?.customClaims?.role ?? profile.data()?.role ?? "customer";
  console.log(JSON.stringify({
    uid,
    authLogin: Boolean(user),
    phone: user?.phoneNumber ?? profile.data()?.phone ?? null,
    name: profile.data()?.name ?? user?.displayName ?? null,
    username: profile.data()?.username ?? null,
    role,
    hasProfile: profile.exists,
    vendorCompanies: vendors.docs.map((v) => `${v.id} (${v.data().businessName})`),
    applications: apps.docs.map((a) => `${a.id} (${a.data().status})`),
    usernames: names.docs.map((n) => n.id),
  }, null, 2));

  if (!confirm) continue;
  if (role === "super_admin") {
    console.log("Refusing to delete an admin account.");
    continue;
  }
  const delWhere = async (col, field, value) => {
    const snap = await db.collection(col).where(field, "==", value).get();
    for (const d of snap.docs) await d.ref.delete();
    return snap.size;
  };
  for (const v of vendors.docs) {
    console.log(`  products removed: ${await delWhere("products", "vendorId", v.id)}`);
    console.log(`  B2B offers removed: ${await delWhere("bulkListings", "vendorId", v.id)}`);
    console.log(`  B2B requests removed: ${await delWhere("bulkRequests", "vendorId", v.id)}`);
    await v.ref.delete();
  }
  for (const a of apps.docs) await a.ref.delete();
  for (const n of names.docs) await n.ref.delete();
  if (profile.exists) await profile.ref.delete();
  if (user) await auth.deleteUser(uid);
  console.log(`Deleted account ${uid}.`);
}
if (!confirm) console.log("\nLook-up only. Re-run with --confirm to delete.");
