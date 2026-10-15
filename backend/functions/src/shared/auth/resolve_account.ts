import { db } from "../firebase";
import { normalizeUsername } from "./password";

/// Maps what someone typed into the sign-in box to the uids it could mean.
///
/// - No "@": a username, looked up in `usernames` (at most one uid).
/// - Contains "@": the email they applied/approved with. Every account
///   with that email on users/{uid}.email, plus every approved
///   vendorApplications row with it — someone who applied more than once
///   with the same email has several candidates, and the password decides
///   which one they are. This only narrows down WHICH account; the
///   password (and the new-device OTP) are still required, so an email
///   typed into someone else's application can't be used to get in.
///
/// Returns [] when nothing matches; callers must answer with the same
/// generic "incorrect" error as a wrong password.
export async function resolveAccountUids(identifier: string): Promise<string[]> {
  const value = normalizeUsername(identifier);
  if (!value) return [];

  if (!value.includes("@")) {
    const snap = await db.collection("usernames").doc(value).get();
    return snap.exists ? [snap.data()!.uid as string] : [];
  }

  const [byUser, byApplication] = await Promise.all([
    db.collection("users").where("email", "==", value).limit(5).get(),
    db.collection("vendorApplications").where("email", "==", value).where("status", "==", "approved").limit(5).get(),
  ]);
  const uids = new Set<string>();
  byUser.docs.forEach((d) => uids.add(d.id));
  byApplication.docs.forEach((d) => uids.add(d.data().uid as string));
  return [...uids];
}
