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

/// True when a Firebase Auth account already holds this phone number
/// (every account made by signUp does).
export async function isPhoneRegistered(phone: string): Promise<boolean> {
  try {
    await auth.getUserByPhoneNumber(phone);
    return true;
  } catch (e) {
    if ((e as { code?: string }).code === "auth/user-not-found") return false;
    throw e;
  }
}
