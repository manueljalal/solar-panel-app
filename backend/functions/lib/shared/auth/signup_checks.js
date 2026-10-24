"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isUsernameAvailable = isUsernameAvailable;
exports.isPhoneRegistered = isPhoneRegistered;
const firebase_1 = require("../firebase");
/// A username is free unless `usernames/{name}` points at a real account.
/// A reservation whose users/{uid} doc doesn't exist is an orphan — left by
/// a sign-up that was interrupted after reserving — and must not lock the
/// name forever, so it counts as available (signUp then overwrites it).
async function isUsernameAvailable(username) {
    const snap = await firebase_1.db.collection("usernames").doc(username).get();
    if (!snap.exists)
        return true;
    const uid = snap.data()?.uid;
    if (!uid)
        return true;
    return !(await firebase_1.db.collection("users").doc(uid).get()).exists;
}
/// True when a Firebase Auth account already holds this phone number
/// (every account made by signUp does).
async function isPhoneRegistered(phone) {
    try {
        await firebase_1.auth.getUserByPhoneNumber(phone);
        return true;
    }
    catch (e) {
        if (e.code === "auth/user-not-found")
            return false;
        throw e;
    }
}
