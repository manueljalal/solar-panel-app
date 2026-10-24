import { logger } from "firebase-functions";
import { db, auth } from "../firebase";

/// A username is free unless `usernames/{name}` points at a real account.
/// A reservation whose users/{uid} doc doesn't exist is an orphan — left by
/// a sign-up that was interrupted after reserving — and must not lock the
/// name forever, so it counts as available (signUp then overwrites it).
export async function isUsernameAvailable(username: string): Promise<boolean> {
  const snap = await db.collection("usernames").doc(username).get();
  if (!snap.exists) return true;
  const uid = snap.data()?.uid as string | undefined;
  if (!uid) return true;
  return !(await db.collection("users").doc(uid).get()).exists;
}

export interface PhoneAccount {
  uid: string;
  /// True when the Auth account holding this phone is a leftover from an
  /// interrupted sign-up: no users/{uid} profile, no vendor/admin role and
  /// no vendor company. Such an account can never be signed into (sign-in
  /// needs the profile's password hash) but still blocks the phone number.
  orphan: boolean;
}

/// The Firebase Auth account that holds [phone], if any.
export async function findPhoneAccount(phone: string): Promise<PhoneAccount | null> {
  let user;
  try {
    user = await auth.getUserByPhoneNumber(phone);
  } catch (e) {
    if ((e as { code?: string }).code === "auth/user-not-found") return null;
    throw e;
  }
  const role = user.customClaims?.role as string | undefined;
  if (role === "vendor" || role === "super_admin") return { uid: user.uid, orphan: false };
  const [profile, vendor] = await Promise.all([
    db.collection("users").doc(user.uid).get(),
    db.collection("vendors").where("ownerUid", "==", user.uid).limit(1).get(),
  ]);
  return { uid: user.uid, orphan: !profile.exists && vendor.empty };
}

/// True when the phone belongs to a real account (orphans don't count —
/// signUp clears them once the caller has proven they own the phone).
export async function isPhoneRegistered(phone: string): Promise<boolean> {
  const account = await findPhoneAccount(phone);
  return account !== null && !account.orphan;
}

/// Deletes an orphaned Auth account and any username reservation pointing
/// at it. Only ever called for accounts findPhoneAccount marked orphan.
export async function removeOrphanAccount(uid: string): Promise<void> {
  logger.warn("Removing orphaned auth account left by an interrupted sign-up", { uid });
  await auth.deleteUser(uid);
  const names = await db.collection("usernames").where("uid", "==", uid).get();
  await Promise.all(names.docs.map((d) => d.ref.delete()));
}
