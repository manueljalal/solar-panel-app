"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.checkSignUp = void 0;
const https_1 = require("firebase-functions/v2/https");
const signup_checks_1 = require("../shared/auth/signup_checks");
const password_1 = require("../shared/auth/password");
const E164_PATTERN = /^\+[1-9]\d{6,14}$/;
/// Pre-flight for the sign-up form, called BEFORE a WhatsApp code is sent:
/// tells the user that the username or phone is already taken while they
/// can still change it, instead of after the one-time code was spent.
/// Needs no sign-in (the user has no account yet). Like any sign-up form it
/// reveals whether a username/phone is registered; the code requirement on
/// signUp itself is what protects accounts.
exports.checkSignUp = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    const username = (0, password_1.normalizeUsername)(request.data?.username ?? "");
    const phone = request.data?.phone?.trim() ?? "";
    if (!(0, password_1.isValidUsername)(username)) {
        throw new https_1.HttpsError("invalid-argument", "username must be 3-20 characters: lowercase letters, numbers, underscores only.");
    }
    if (!E164_PATTERN.test(phone)) {
        throw new https_1.HttpsError("invalid-argument", "phone must be in E.164 format, e.g. +9647501234567.");
    }
    const [usernameFree, phoneTaken] = await Promise.all([(0, signup_checks_1.isUsernameAvailable)(username), (0, signup_checks_1.isPhoneRegistered)(phone)]);
    return { usernameTaken: !usernameFree, phoneTaken };
});
