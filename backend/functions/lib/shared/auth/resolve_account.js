"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.resolveAccountUids = resolveAccountUids;
const firebase_1 = require("../firebase");
const password_1 = require("./password");
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
async function resolveAccountUids(identifier) {
    const value = (0, password_1.normalizeUsername)(identifier);
    if (!value)
        return [];
    if (!value.includes("@")) {
        const snap = await firebase_1.db.collection("usernames").doc(value).get();
        return snap.exists ? [snap.data().uid] : [];
    }
    const [byUser, byApplication] = await Promise.all([
        firebase_1.db.collection("users").where("email", "==", value).limit(5).get(),
        firebase_1.db.collection("vendorApplications").where("email", "==", value).where("status", "==", "approved").limit(5).get(),
    ]);
    const uids = new Set();
    byUser.docs.forEach((d) => uids.add(d.id));
    byApplication.docs.forEach((d) => uids.add(d.data().uid));
    return [...uids];
}
