import { db, auth } from "./firebase";

async function deleteWhere(collection: string, field: string, value: string): Promise<number> {
  const snap = await db.collection(collection).where(field, "==", value).get();
  for (let i = 0; i < snap.docs.length; i += 400) {
    const batch = db.batch();
    snap.docs.slice(i, i + 400).forEach((d) => batch.delete(d.ref));
    await batch.commit();
  }
  return snap.size;
}

/// Permanently removes an account: vendor company + its products and B2B
/// posts (if any), applications, username, profile and finally the Auth
/// login (last, so a failure part-way can simply be retried). Orders,
/// quote requests and service requests are kept as business records.
export async function deleteAccountData(uid: string): Promise<Record<string, number>> {
  const removed: Record<string, number> = {};
  const vendors = await db.collection("vendors").where("ownerUid", "==", uid).get();
  for (const v of vendors.docs) {
    removed.products = (removed.products ?? 0) + (await deleteWhere("products", "vendorId", v.id));
    removed.bulkListings = (removed.bulkListings ?? 0) + (await deleteWhere("bulkListings", "vendorId", v.id));
    removed.bulkRequests = (removed.bulkRequests ?? 0) + (await deleteWhere("bulkRequests", "vendorId", v.id));
    await v.ref.delete();
  }
  removed.vendors = vendors.size;
  removed.applications = await deleteWhere("vendorApplications", "uid", uid);
  removed.usernames = await deleteWhere("usernames", "uid", uid);
  await db.collection("users").doc(uid).delete();
  const authUser = await auth.getUser(uid).catch(() => null);
  if (authUser) await auth.deleteUser(uid);
  return removed;
}
